import 'dart:io';

import 'package:args/args.dart';
import 'package:draqos_server/draqos_server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

/// `draqosd` — headless DRAQOS daemon.
///
/// Binds localhost only; sharing happens through Tailscale Serve
/// (tailnet admin API) and Tailscale Funnel (/r/* redirect only).
Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('port', abbr: 'p', defaultsTo: '8471')
    ..addOption(
      'data-dir',
      defaultsTo: '${Platform.environment['HOME'] ?? '.'}/.local/share/draqosd',
    )
    ..addOption(
      'tunnel',
      allowed: ['off', 'serve', 'funnel', 'cloudflare'],
      defaultsTo: 'off',
    )
    ..addOption('public-port', defaultsTo: '443')
    ..addFlag('help', abbr: 'h', negatable: false);
  final opts = parser.parse(args);
  if (opts.flag('help')) {
    stdout.writeln('draqosd — DRAQOS headless daemon\n');
    stdout.writeln(parser.usage);
    return;
  }
  final port = int.parse(opts['port'] as String);
  final dataDir = Directory(opts['data-dir'] as String);
  await dataDir.create(recursive: true);
  final store = SqliteStore.open('${dataDir.path}/draqos.db');
  final auth = await AdminAuth.load(dataDir);
  final runner = ProcessCommandRunner();
  final tailscale = TailscaleTunnelProvider(
    runner: runner,
    publicPort: int.parse(opts['public-port'] as String),
  );

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(
        buildHandler(
          store: store,
          auth: auth,
          tunnels: tailscale,
          localPort: port,
        ),
      );

  await io.serve(handler, InternetAddress.loopbackIPv4, port);
  stdout.writeln('draqosd listening on http://127.0.0.1:$port');

  switch (opts['tunnel']) {
    case 'serve':
      stdout.writeln('serve: ${await tailscale.startPrivate(port)}');
    case 'funnel':
      stdout.writeln('funnel: ${await tailscale.startPublic(port)}');
    case 'cloudflare':
      final cf = CloudflareTunnelProvider(runner: runner);
      stdout.writeln('cloudflare: ${await cf.startPublic(port)}');
  }
  stdout.writeln('admin token: ${auth.token} (stored in ${dataDir.path})');
  stdout.writeln('Pair this device from the desktop app to scan the QR.');
}
