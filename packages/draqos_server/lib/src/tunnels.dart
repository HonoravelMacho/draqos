import 'dart:convert';

import 'package:draqos_core/draqos_core.dart';

import 'command_runner.dart';

/// `tailscale status --json` info needed by the daemon.
class TailnetInfo {
  final String dnsName;
  final String tailnet;
  final bool online;

  const TailnetInfo({
    required this.dnsName,
    required this.tailnet,
    required this.online,
  });
}

Future<TailnetInfo> tailscaleInfo(
  CommandRunner runner, {
  String exe = 'tailscale',
}) async {
  try {
    final res = await runner.run(exe, ['status', '--json']);
    if (res.exitCode != 0) {
      return const TailnetInfo(dnsName: '', tailnet: '', online: false);
    }
    final json = jsonDecode(res.stdout) as Map<String, dynamic>;
    final self = json['Self'] as Map<String, dynamic>? ?? {};
    final dns = (self['DNSName'] as String? ?? '').replaceAll(
      RegExp(r'\.$'),
      '',
    );
    final tailnet = dns.contains('.') ? dns.split('.').skip(1).join('.') : '';
    return TailnetInfo(dnsName: dns, tailnet: tailnet, online: dns.isNotEmpty);
  } catch (_) {
    return const TailnetInfo(dnsName: '', tailnet: '', online: false);
  }
}

/// Default TunnelProvider: Tailscale Serve (private, tailnet-only) +
/// Tailscale Funnel (public, ONLY the /r/* path).
///
/// Verified against the official CLI references (validated Jan 2026):
/// - `tailscale serve --bg --https=<port> [--set-path=<p>] <target>`
/// - `tailscale funnel --bg --https=<port> [--set-path=<p>] <target>`
/// - Funnel ports limited to 443 / 8443 / 10000; a port cannot be
///   Serve-shared and Funnel-shared at the same time.
/// - serve/funnel resume automatically after reboot when `--bg` was used.
class TailscaleTunnelProvider implements TunnelProvider {
  final CommandRunner runner;
  final String exe;

  /// Public (funnel) port. Must be 443, 8443 or 10000.
  final int publicPort;

  TunnelStatus _status = TunnelStatus.stopped;
  String _lastError = '';
  bool _serveOn = false;
  bool _funnelOn = false;
  String _baseUrl = '';

  TailscaleTunnelProvider({
    required this.runner,
    this.exe = 'tailscale',
    this.publicPort = 443,
  });

  String get lastError => _lastError;

  @override
  String get name => 'tailscale';

  @override
  List<int> get publicPorts => const [443, 8443, 10000];

  @override
  Future<TunnelStatus> status() async => _status;

  Future<TailnetInfo> info() => tailscaleInfo(runner, exe: exe);

  @override
  Future<Result<String>> startPrivate(int localPort) async {
    _status = TunnelStatus.starting;
    final info = await this.info();
    if (!info.online) {
      _status = TunnelStatus.error;
      _lastError = 'Tailscale is off or unreachable (is the client up?)';
      return const Err('tailscale offline', code: 'tailscale_off');
    }
    final res = await runner.run(exe, [
      'serve',
      '--bg',
      '--https=443',
      'http://127.0.0.1:$localPort',
    ]);
    if (res.exitCode != 0) {
      _status = TunnelStatus.error;
      _lastError = res.stderr.trim().isEmpty
          ? res.stdout.trim()
          : res.stderr.trim();
      return Err('tailscale serve failed: $_lastError', code: 'serve_failed');
    }
    _serveOn = true;
    _status = TunnelStatus.running;
    _baseUrl = 'https://${info.dnsName}';
    return Ok(_baseUrl);
  }

  @override
  Future<Result<String>> startPublic(int localPort) async {
    if (!publicPorts.contains(publicPort)) {
      return Err('funnel port must be one of $publicPorts', code: 'bad_port');
    }
    _status = TunnelStatus.starting;
    final info = await this.info();
    if (!info.online) {
      _status = TunnelStatus.error;
      _lastError = 'Tailscale is off or unreachable (is the client up?)';
      return const Err('tailscale offline', code: 'tailscale_off');
    }
    // A port cannot be Serve-shared and Funnel-shared at once: the most
    // recent command wins, so release Serve before enabling Funnel.
    if (_serveOn) {
      await runner.run(exe, ['serve', '--https=443', 'off']);
      _serveOn = false;
    }
    // Scope the funnel to the redirect path ONLY; the admin API must
    // never be reachable publicly. If path scoping is rejected, refuse
    // to go public instead of exposing everything.
    final res = await runner.run(exe, [
      'funnel',
      '--bg',
      '--https=$publicPort',
      '--set-path=/r',
      'http://127.0.0.1:$localPort/r',
    ]);
    if (res.exitCode != 0) {
      _status = TunnelStatus.error;
      _lastError = res.stderr.trim().isEmpty
          ? res.stdout.trim()
          : res.stderr.trim();
      return Err(
        'tailscale funnel failed (admin API stays private): $_lastError',
        code: 'funnel_failed',
      );
    }
    _funnelOn = true;
    _status = TunnelStatus.running;
    _baseUrl = 'https://${info.dnsName}';
    return Ok(_baseUrl);
  }

  @override
  Future<Result<void>> stop() async {
    if (_funnelOn) {
      await runner.run(exe, [
        'funnel',
        '--https=$publicPort',
        '--set-path=/r',
        'off',
      ]);
      _funnelOn = false;
    }
    if (_serveOn) {
      await runner.run(exe, ['serve', '--https=443', 'off']);
      _serveOn = false;
    }
    _status = TunnelStatus.stopped;
    return const Ok(null);
  }
}

/// Optional TunnelProvider backed by `cloudflared` (quick tunnel or
/// named tunnel). Public scope should likewise be limited to /r/* via
/// ingress rules; see README.
class CloudflareTunnelProvider implements TunnelProvider {
  final CommandRunner runner;
  final String exe;
  final String? hostname;

  TunnelStatus _status = TunnelStatus.stopped;
  String _baseUrl = '';

  CloudflareTunnelProvider({
    required this.runner,
    this.exe = 'cloudflared',
    this.hostname,
  });

  @override
  String get name => 'cloudflare';

  @override
  List<int> get publicPorts => const [443, 8443, 10000];

  @override
  Future<TunnelStatus> status() async => _status;

  @override
  Future<Result<String>> startPrivate(int localPort) async {
    // cloudflared has no tailnet concept; "private" here means:
    // do not start any tunnel (local access only).
    _status = TunnelStatus.running;
    _baseUrl = 'http://127.0.0.1:$localPort';
    return Ok(_baseUrl);
  }

  @override
  Future<Result<String>> startPublic(int localPort) async {
    _status = TunnelStatus.starting;
    final host = hostname;
    final args = <String>[
      'tunnel',
      '--url',
      'http://127.0.0.1:$localPort',
      if (host != null && host.isNotEmpty) ...['--hostname', host],
    ];
    final res = await runner.run(exe, args);
    if (res.exitCode != 0) {
      _status = TunnelStatus.error;
      final err = res.stderr.trim().isEmpty
          ? res.stdout.trim()
          : res.stderr.trim();
      return Err('cloudflared failed: $err', code: 'cloudflared_failed');
    }
    _status = TunnelStatus.running;
    _baseUrl = (host != null && host.isNotEmpty)
        ? 'https://$host'
        : res.stdout.trim();
    return Ok(_baseUrl);
  }

  @override
  Future<Result<void>> stop() async {
    _status = TunnelStatus.stopped;
    return const Ok(null);
  }
}
