import 'package:draqos_core/draqos_core.dart';
import 'package:draqos_render/draqos_render.dart';
import 'package:draqos_ui/draqos_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_daemon.dart';
import 'session.dart';

/// Pair Android editor <-> PC daemon.
/// Paste the `draqos://pair?...` code shown on the desktop
/// (camera scanning is a planned enhancement).
class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  final _code = TextEditingController();
  String? _desktopPayload;
  bool _loadingDesktop = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pairing = ref.watch(pairingProvider);
    final isAndroid = ref.watch(isAndroidProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('DRAQOS · PAIRING')),
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
                    'STATUS: ${pairing == null ? 'NOT PAIRED' : 'PAIRED → ${pairing.machine}'}',
                  ),
                  if (pairing != null) ...[
                    Text(pairing.baseUrl, style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    DraqButton(
                      label: 'Unpair',
                      primary: false,
                      onPressed: () async {
                        ref.read(pairingProvider.notifier).state = null;
                        await ref.read(pairingStoreProvider).clear();
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            DraqPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PASTE PAIRING CODE FROM PC'),
                  const Text(
                    'On the desktop: Daemon tab → Show pairing QR → copy the code. '
                    'Camera scanning is planned; paste works everywhere.',
                    style: TextStyle(fontSize: 12),
                  ),
                  TextField(
                    controller: _code,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'draqos://pair?base=…&token=…',
                    ),
                  ),
                  const SizedBox(height: 8),
                  DraqButton(
                    label: 'Pair',
                    onPressed: () => _pair(context, ref),
                  ),
                ],
              ),
            ),
            if (!isAndroid) ...[
              const SizedBox(height: 10),
              DraqPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DESKTOP: SHOW MY PAIRING CODE'),
                    const Text(
                      'Reads the local daemon token + tailnet name. '
                      'Changing hostname/tailnet later BREAKS existing dynamic QRs.',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    DraqButton(
                      label: 'Show pairing QR',
                      primary: false,
                      onPressed: _loadingDesktop
                          ? null
                          : () => _showDesktop(context),
                    ),
                    if (_desktopPayload != null) ...[
                      const SizedBox(height: 8),
                      _PairingQr(code: _desktopPayload!),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pair(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final payload = PairingPayload.decode(_code.text.trim());
      ref.read(pairingProvider.notifier).state = payload;
      await ref.read(pairingStoreProvider).save(payload);
      messenger.showSnackBar(
        SnackBar(content: Text('Paired with ${payload.machine}')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Invalid code: $e')));
    }
  }

  Future<void> _showDesktop(BuildContext context) async {
    setState(() => _loadingDesktop = true);
    try {
      final payload = await LocalDaemon.buildPairingPayload();
      if (payload == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Local daemon not found. Start it from the Daemon tab first.',
              ),
            ),
          );
        }
      } else {
        setState(() => _desktopPayload = payload.encode());
      }
    } finally {
      if (mounted) setState(() => _loadingDesktop = false);
    }
  }
}

/// Renders the pairing payload as a pluggable QR (static render path).
class _PairingQr extends StatelessWidget {
  final String code;
  const _PairingQr({required this.code});

  @override
  Widget build(BuildContext context) {
    final model = QrRenderModel.fromData(code, const QrStyle());
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(painter: DraqQrPainter(model: model)),
    );
  }
}
