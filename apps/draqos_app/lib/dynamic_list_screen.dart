import 'package:draqos_client/draqos_client.dart';
import 'package:draqos_core/draqos_core.dart';
import 'package:draqos_ui/draqos_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dynamic_editor_screen.dart';
import 'session.dart';

final _refreshTick = StateProvider<int>((ref) => 0);

/// Dynamic QR list: full CRUD entry point + scan totals.
class DynamicListScreen extends ConsumerStatefulWidget {
  const DynamicListScreen({super.key});

  @override
  ConsumerState<DynamicListScreen> createState() => _DynamicListState();
}

class _DynamicListState extends ConsumerState<DynamicListScreen> {
  DynamicQrRepository? _repo;
  Future<Result<List<DynamicQr>>>? _future;

  void _reload(DynamicQrRepository? repo) {
    _repo = repo;
    _future = repo?.list();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repoProvider);
    // Cache the future: recreating it per build (e.g. on every
    // progress-animation frame) restarts the wait forever.
    if (!identical(_repo, repo)) _reload(repo);
    ref.listen<int>(_refreshTick, (_, __) {
      if (mounted) setState(() => _reload(repo));
    });
    final tokens = DraqosTokens.of(context);
    if (repo == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('DRAQOS · DYNAMIC')),
        body: Center(
          child: DraqPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('NOT PAIRED'),
                const SizedBox(height: 8),
                const Text(
                  'Pair this editor with your PC daemon first (Pair tab).',
                ),
                const SizedBox(height: 12),
                DraqButton(
                  label: 'Go to pairing',
                  primary: false,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('DRAQOS · DYNAMIC'),
        backgroundColor: tokens.hullDark,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(_refreshTick.notifier).state++,
          ),
        ],
      ),
      body: FutureBuilder<Result<List<DynamicQr>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            final err = snap.error;
            final hint = err is DaemonUnreachable
                ? unreachableHint(err)
                : '$err';
            return Center(
              child: DraqPanel(child: Text('UNREACHABLE\n\n$hint')),
            );
          }
          final res = snap.data!;
          if (res is Err<List<DynamicQr>>) {
            return Center(child: Text('Error: ${(res).message}'));
          }
          final items = (res as Ok<List<DynamicQr>>).value;
          if (items.isEmpty) {
            return const Center(
              child: Text('No dynamic QRs yet — create one below.'),
            );
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) => _QrTile(qr: items[i], repo: repo),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const DynamicEditorScreen())),
        label: const Text('NEW QR'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class _QrTile extends ConsumerWidget {
  final DynamicQr qr;
  final DynamicQrRepository repo;
  const _QrTile({required this.qr, required this.repo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider(qr.id));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: DraqPanel(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${qr.name}  ·  /r/${qr.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: qr.active ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Text(
                    qr.active ? 'ACTIVE' : 'OFF',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
            Text(
              qr.destinationUrl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            stats.when(
              data: (s) => Text(
                'Scans: ${s.total}',
                style: const TextStyle(fontSize: 12),
              ),
              loading: () =>
                  const Text('Scans: …', style: TextStyle(fontSize: 12)),
              error: (_, __) =>
                  const Text('Scans: ?', style: TextStyle(fontSize: 12)),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DynamicEditorScreen(existing: qr),
                    ),
                  ),
                  child: const Text('EDIT'),
                ),
                TextButton(
                  onPressed: () => _confirmDelete(context, ref),
                  child: const Text('DELETE'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete dynamic QR?'),
        content: Text(
          'This removes /r/${qr.id}. Printed codes pointing at it will 404.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final res = await repo.delete(qr.id);
      if (res is Err<void>) {
        messenger.showSnackBar(
          SnackBar(content: Text('Delete failed: ${res.message}')),
        );
      } else {
        ref.read(_refreshTick.notifier).state++;
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e is DaemonUnreachable ? unreachableHint(e) : 'Delete failed: $e',
          ),
        ),
      );
    }
  }
}
