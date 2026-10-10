import 'package:draqos_client/draqos_client.dart';
import 'package:draqos_core/draqos_core.dart';
import 'package:draqos_ui/draqos_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_daemon.dart';
import 'session.dart';

/// Desktop daemon control: start/stop/status + tunnel toggles.
/// Android builds show a client-only notice instead.
class DaemonScreen extends ConsumerStatefulWidget {
  const DaemonScreen({super.key});

  @override
  ConsumerState<DaemonScreen> createState() => _DaemonScreenState();
}

class _DaemonScreenState extends ConsumerState<DaemonScreen> {
  LocalDaemon? _daemon;
  DaemonStatus? _status;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _daemon?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = ref.watch(isAndroidProvider);
    if (isAndroid) {
      return Scaffold(
        appBar: AppBar(title: const Text('DRAQOS · DAEMON')),
        body: const Center(
          child: DraqPanel(
            child: Text(
              'CLIENT MODE\n\nAndroid never runs the server — it only edits.\n'
              'Keep your PC online with draqosd + Tailscale running.\n'
              'Remember: Android allows a single VPN at a time.',
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('DRAQOS · DAEMON')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DraqPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _daemon?.running == true
                        ? 'DAEMON: RUNNING (localhost)'
                        : 'DAEMON: STOPPED',
                  ),
                  if (_status != null)
                    Text(
                      'Host: ${_status!.hostname} · Tailnet: ${_status!.tailnet} · v${_status!.version}',
                    ),
                  if (_error != null) Text('Error: $_error'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DraqButton(
                          label: 'Start',
                          onPressed: _busy ? null : () => _start(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DraqButton(
                          label: 'Stop',
                          primary: false,
                          onPressed: _busy ? null : () => _stop(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DraqButton(
                          label: 'Status',
                          primary: false,
                          onPressed: _busy ? null : () => _refresh(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const DraqPanel(
              child: Text(
                'SHARING (needs Tailscale on this PC)\n'
                'Serve = tailnet-only admin API. Funnel = public /r/* only.\n'
                'WARNING: renaming the machine or tailnet, or reinstalling '
                'Tailscale, changes the public base URL and BREAKS every '
                'printed dynamic QR. You will be asked to confirm.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _start(BuildContext context) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final d = LocalDaemon();
      await d.start();
      _daemon = d;
      await _refresh();
    } catch (e) {
      setState(
        () =>
            _error = 'Could not start draqosd (is it installed / on PATH?): $e',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stop() async {
    await _daemon?.stop();
    _daemon = null;
    setState(() {
      _status = null;
    });
  }

  Future<void> _refresh() async {
    final token = await LocalDaemon.readLocalToken();
    if (token == null) {
      setState(() => _error = 'No local token yet — start the daemon first.');
      return;
    }
    try {
      final client = DraqosClient(
        baseUrl: 'http://127.0.0.1:8471',
        token: token,
      );
      final st = await client.status();
      client.close();
      setState(() {
        _status = st;
        _error = null;
      });
    } catch (e) {
      setState(
        () => _error = e is DaemonUnreachable
            ? unreachableHint(e)
            : 'Status failed: $e',
      );
    }
  }
}
