import 'dart:typed_data';

import 'package:draqos_core/draqos_core.dart';
import 'package:draqos_render/draqos_render.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QrMatrix', () {
    test('builds H-level matrix with intact finder patterns', () {
      final m = QrMatrix.build('https://example.com/r/abc');
      expect(m.size, greaterThan(20));
      // Top-left finder: 7x7 border dark, inner 3x3 dark.
      expect(m.isDark(0, 0), isTrue);
      expect(m.isDark(6, 6), isTrue);
      expect(m.isDark(1, 1), isFalse);
      expect(m.isDark(3, 3), isTrue);
      expect(m.dataDarkCount, greaterThan(0));
    });
  });

  group('color utils', () {
    test('hex parses and round-trips', () {
      final c = hexToColor('#35F1FF');
      expect(colorToHex(c), '#35F1FF');
    });

    test('contrast ratio black/white is ~21', () {
      expect(
        contrastRatio(hexToColor('#000000'), hexToColor('#FFFFFF')),
        closeTo(21, 0.5),
      );
    });

    test('auto-contrast picks readable color on light and dark bg', () {
      final onWhite = autoModuleColor(
        bgLuminance: 1.0,
        darkOption: hexToColor('#111111'),
        lightOption: hexToColor('#FFFFFF'),
        minRatio: 3.0,
      );
      expect(colorToHex(onWhite), '#111111');
      final onBlack = autoModuleColor(
        bgLuminance: 0.0,
        darkOption: hexToColor('#111111'),
        lightOption: hexToColor('#FFFFFF'),
        minRatio: 3.0,
      );
      expect(colorToHex(onBlack), '#FFFFFF');
    });
  });

  group('QrRenderModel', () {
    test('frame aspects resolve per preset', () {
      QrRenderModel modelFor(FramePreset p) => QrRenderModel.fromData(
        'hi',
        QrStyle(framePreset: p, frameAspect: 2.0),
      );
      expect(modelFor(FramePreset.square).frameAspect, 1.0);
      expect(
        modelFor(FramePreset.a4Landscape).frameAspect,
        closeTo(1.414, 0.001),
      );
      expect(modelFor(FramePreset.golden).frameAspect, closeTo(1.618, 0.001));
      expect(modelFor(FramePreset.free).frameAspect, 2.0);
    });
  });

  group('export', () {
    test('SVG contains modules and eyes', () {
      final model = QrRenderModel.fromData(
        'https://example.com',
        const QrStyle(),
      );
      final svg = exportSvg(model);
      expect(svg, contains('<svg'));
      expect(svg, contains('</svg>'));
      expect('<rect'.allMatches(svg).length, greaterThan(100));
    });

    test('PDF bytes are a valid document', () async {
      final model = QrRenderModel.fromData(
        'https://example.com',
        const QrStyle(),
      );
      final bytes = await exportPdf(model);
      expect(bytes.lengthInBytes, greaterThan(1000));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    testWidgets('PNG export produces image bytes', (tester) async {
      final model = QrRenderModel.fromData(
        'https://example.com',
        const QrStyle(),
      );
      final png =
          (await tester.runAsync(() => exportPng(model, sizePx: 256))) ??
          Uint8List(0);
      expect(png.lengthInBytes, greaterThan(1000));
      // PNG magic.
      expect(png.sublist(0, 4), [137, 80, 78, 71]);
    });
  });
}
