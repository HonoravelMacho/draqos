import 'package:draqos_render/draqos_render.dart';
import 'package:draqos_ui/draqos_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'editor_controller.dart';

final editorProvider = ChangeNotifierProvider<EditorController>(
  (ref) => EditorController(),
);

/// Live QR preview: paints [model] with optional bg/icon images.
class QrPreview extends ConsumerWidget {
  const QrPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorProvider);
    final model = editor.buildModel();
    return DraqPanel(
      padding: const EdgeInsets.all(12),
      child: AspectRatio(
        aspectRatio: model.frameAspect,
        child: CustomPaint(
          painter: DraqQrPainter(
            model: model,
            backgroundImage: editor.backgroundImage,
            iconImage: editor.iconImage,
          ),
        ),
      ),
    );
  }
}
