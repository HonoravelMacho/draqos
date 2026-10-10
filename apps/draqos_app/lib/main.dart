import 'package:draqos_ui/draqos_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'static_editor_screen.dart';

void main() {
  runApp(const ProviderScope(child: DraqosApp()));
}

/// Composition root: theme + providers + routes. No business logic.
class DraqosApp extends ConsumerWidget {
  const DraqosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'DRAQOS',
      theme: draqosTheme(),
      home: const StaticEditorScreen(),
    );
  }
}
