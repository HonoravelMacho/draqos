import 'package:draqos_ui/draqos_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'daemon_screen.dart';
import 'dynamic_list_screen.dart';
import 'pairing_screen.dart';
import 'session.dart';
import 'static_editor_screen.dart';

void main() {
  runApp(const ProviderScope(child: DraqosApp()));
}

/// Composition root: theme + providers + routes. No business logic.
class DraqosApp extends ConsumerStatefulWidget {
  const DraqosApp({super.key});

  @override
  ConsumerState<DraqosApp> createState() => _DraqosAppState();
}

class _DraqosAppState extends ConsumerState<DraqosApp> {
  int _tab = 0;
  bool _restored = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_restored) {
      _restored = true;
      _restorePairing();
    }
  }

  Future<void> _restorePairing() async {
    final saved = await ref.read(pairingStoreProvider).load();
    if (saved != null && mounted) {
      ref.read(pairingProvider.notifier).state = saved;
    }
  }

  static const _tabs = [
    StaticEditorScreen(),
    DynamicListScreen(),
    PairingScreen(),
    DaemonScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DRAQOS',
      theme: draqosTheme(),
      home: Scaffold(
        body: IndexedStack(index: _tab, children: _tabs),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard), label: 'Studio'),
            NavigationDestination(
              icon: Icon(Icons.dynamic_feed),
              label: 'Dynamic',
            ),
            NavigationDestination(icon: Icon(Icons.link), label: 'Pair'),
            NavigationDestination(icon: Icon(Icons.dns), label: 'Daemon'),
          ],
        ),
      ),
    );
  }
}
