import 'dart:typed_data';

import 'package:draqos_core/draqos_core.dart';
import 'package:draqos_render/draqos_render.dart';
import 'package:flutter_test/flutter_test.dart';

/// Decode PNG bytes with zxing2 (mirrors the in-app "Testar leitura").
String decodePng(Uint8List png) => decodeQrPng(png);

void main() {
  const data = 'https://example.com/r/abc123';

  group('readability across presets x module shapes', () {
    final combos = [
      for (final frame in FramePreset.values)
        for (final shape in ModuleShape.values) (frame, shape),
    ];
    for (final (frame, shape) in combos) {
      testWidgets('decodes ${frame.name} + ${shape.name} (+ eye variants)', (
        tester,
      ) async {
        final model = QrRenderModel.fromData(
          data,
          QrStyle(
            framePreset: frame,
            frameAspect: frame == FramePreset.free ? 1.3 : 1.0,
            moduleShape: shape,
            eyeOuterShape: EyeOuterShape.rounded,
            eyeInnerShape: EyeInnerShape.circle,
          ),
        );
        final png = (await tester.runAsync(
          () => exportPng(model, sizePx: 800),
        ))!;
        expect(decodePng(png), data);
      });
    }
  });

  testWidgets('decodes default style (square eyes)', (tester) async {
    final model = QrRenderModel.fromData(data, const QrStyle());
    final png = (await tester.runAsync(() => exportPng(model, sizePx: 800)))!;
    expect(decodePng(png), data);
  });
}
