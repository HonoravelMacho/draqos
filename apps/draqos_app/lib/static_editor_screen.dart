import 'dart:io';

import 'package:draqos_core/draqos_core.dart';
import 'package:draqos_render/draqos_render.dart';
import 'package:draqos_ui/draqos_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'editor_controller.dart';
import 'qr_preview.dart';

/// Static QR studio: full customization, readability check, export.
class StaticEditorScreen extends ConsumerWidget {
  const StaticEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorProvider);
    final tokens = DraqosTokens.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('DRAQOS · STATIC STUDIO'),
        backgroundColor: tokens.hullDark,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 900;
          final controls = _Controls(editor: editor);
          final preview = const QrPreview();
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: preview),
                SizedBox(
                  width: 420,
                  child: SingleChildScrollView(child: controls),
                ),
              ],
            );
          }
          return SingleChildScrollView(
            child: Column(children: [preview, controls]),
          );
        },
      ),
    );
  }
}

class _Controls extends ConsumerWidget {
  final EditorController editor;
  const _Controls({required this.editor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ed = ref.watch(editorProvider);
    Color parse(String h) {
      var s = h.replaceAll('#', '');
      if (s.length == 6) s = 'FF$s';
      return Color(int.parse(s, radix: 16));
    }

    String hex(Color c) =>
        '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DraqPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CONTENT'),
                TextField(
                  controller: TextEditingController(text: ed.data)
                    ..selection = TextSelection.collapsed(
                      offset: ed.data.length,
                    ),
                  onChanged: ed.setData,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'https://… or any text',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          DraqPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('FRAME'),
                DraqSegmented<FramePreset>(
                  options: FramePreset.values,
                  value: ed.framePreset,
                  onChanged: ed.setFramePreset,
                  labelOf: (v) => v.name,
                ),
                if (ed.framePreset == FramePreset.free)
                  DraqSlider(
                    label: 'Aspect ratio',
                    value: ed.freeAspect,
                    min: 0.5,
                    max: 2.5,
                    onChanged: ed.setFreeAspect,
                  ),
                DraqSlider(
                  label: 'Quiet zone',
                  value: ed.quietZone,
                  min: 2,
                  max: 8,
                  onChanged: ed.setQuietZone,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          DraqPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MODULES & EYES'),
                DraqSegmented<ModuleShape>(
                  options: ModuleShape.values,
                  value: ed.moduleShape,
                  onChanged: ed.setModuleShape,
                  labelOf: (v) => v.name,
                ),
                DraqSegmented<EyeOuterShape>(
                  options: EyeOuterShape.values,
                  value: ed.eyeOuterShape,
                  onChanged: ed.setEyeOuterShape,
                  labelOf: (v) => 'outer ${v.name}',
                ),
                DraqSegmented<EyeInnerShape>(
                  options: EyeInnerShape.values,
                  value: ed.eyeInnerShape,
                  onChanged: ed.setEyeInnerShape,
                  labelOf: (v) => 'inner ${v.name}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          DraqPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('COLORS'),
                DraqColorPicker(
                  label: 'Stroke',
                  value: parse(ed.foregroundHex),
                  onChanged: (c) => ed.setForeground(hex(c)),
                ),
                DraqColorPicker(
                  label: 'Background',
                  value: parse(ed.backgroundHex),
                  onChanged: (c) => ed.setBackground(hex(c)),
                ),
                DraqColorPicker(
                  label: 'Eye outer',
                  value: parse(ed.eyeOuterHex),
                  onChanged: (c) => ed.setEyeOuter(hex(c)),
                ),
                DraqColorPicker(
                  label: 'Eye inner',
                  value: parse(ed.eyeInnerHex),
                  onChanged: (c) => ed.setEyeInner(hex(c)),
                ),
                SwitchListTile(
                  title: const Text('Auto contrast'),
                  value: ed.autoContrast,
                  onChanged: ed.setAutoContrast,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          DraqPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('IMAGES'),
                Text(ed.backgroundName ?? 'No background image'),
                Row(
                  children: [
                    Expanded(
                      child: DraqButton(
                        label: 'BG image',
                        primary: false,
                        onPressed: () => ed.pickBackground(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DraqButton(
                        label: 'Clear BG',
                        primary: false,
                        onPressed: ed.backgroundImage == null
                            ? null
                            : () => ed.clearBackground(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(ed.iconName ?? 'No center icon (PNG/SVG)'),
                Row(
                  children: [
                    Expanded(
                      child: DraqButton(
                        label: 'Icon',
                        primary: false,
                        onPressed: () => ed.pickIcon(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DraqButton(
                        label: 'Clear icon',
                        primary: false,
                        onPressed: ed.iconImage == null
                            ? null
                            : () => ed.clearIcon(),
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  title: const Text('Modules invade icon transparency'),
                  value: ed.iconInvadeTransparent,
                  onChanged: ed.setIconInvade,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          DraqButton(
            label: 'Test read',
            onPressed: () => _testRead(context, ed),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DraqButton(
                  label: 'PNG',
                  primary: false,
                  onPressed: () => _export(context, ed, 'png'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DraqButton(
                  label: 'SVG',
                  primary: false,
                  onPressed: () => _export(context, ed, 'svg'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DraqButton(
                  label: 'PDF',
                  primary: false,
                  onPressed: () => _export(context, ed, 'pdf'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _testRead(BuildContext context, EditorController ed) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final text = await ed.testRead();
      final ok = text == (ed.data.isEmpty ? 'https://example.com' : ed.data);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'READABLE · decoded "$text"' : 'MISMATCH · decoded "$text"',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('NOT READABLE · $e')));
    }
  }

  Future<void> _export(
    BuildContext context,
    EditorController ed,
    String kind,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final model = ed.buildModel();
      late String path;
      if (kind == 'png') {
        final bytes = await exportPng(
          model,
          sizePx: 1024,
          backgroundImage: ed.backgroundImage,
          iconImage: ed.iconImage,
        );
        path = '${dir.path}/draqos_$stamp.png';
        await File(path).writeAsBytes(bytes);
      } else if (kind == 'svg') {
        path = '${dir.path}/draqos_$stamp.svg';
        // ignore: avoid_redundant_argument_values
        await File(path).writeAsString(exportSvg(model));
      } else {
        final bytes = await exportPdf(model);
        path = '${dir.path}/draqos_$stamp.pdf';
        await File(path).writeAsBytes(bytes);
      }
      messenger.showSnackBar(SnackBar(content: Text('Saved $path')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed · $e')));
    }
  }
}
