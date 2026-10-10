import 'package:test/test.dart';
import 'package:draqos_core/draqos_core.dart';

void main() {
  group('validation', () {
    test('short ids accept URL-safe strings', () {
      expect(validateShortId('abc'), isEmpty);
      expect(validateShortId('a-b_9Z'), isEmpty);
      expect(validateShortId('ab'), isNotEmpty);
      expect(validateShortId('a b'), isNotEmpty);
    });

    test('destination URL must be absolute http(s)', () {
      expect(validateDestinationUrl('https://example.com/x'), isEmpty);
      expect(validateDestinationUrl('not-a-url'), isNotEmpty);
      expect(validateDestinationUrl('ftp://example.com'), isNotEmpty);
    });

    test('public URL builder strips trailing slash', () {
      expect(publicQrUrl('https://m.ts.net/', 'a1'), 'https://m.ts.net/r/a1');
    });
  });

  group('entities', () {
    test('DynamicQr json round-trip', () {
      final now = DateTime.utc(2026, 1, 1);
      final qr = DynamicQr(
        id: 'abc',
        name: 'n',
        description: 'd',
        destinationUrl: 'https://example.com',
        styleJson: '{}',
        active: true,
        createdAt: now,
        updatedAt: now,
      );
      final back = DynamicQr.fromJson(qr.toJson());
      expect(back.id, 'abc');
      expect(back.destinationUrl, 'https://example.com');
    });
  });

  group('QrStyle', () {
    test('json round-trip preserves fields', () {
      const s = QrStyle(
        moduleShape: ModuleShape.heart,
        framePreset: FramePreset.golden,
        autoContrast: true,
      );
      final back = QrStyle.decode(s.encode());
      expect(back.moduleShape, ModuleShape.heart);
      expect(back.framePreset, FramePreset.golden);
      expect(back.autoContrast, isTrue);
    });

    test('frame preset aspects', () {
      expect(FramePreset.a4Landscape.aspect, closeTo(1.414, 0.001));
      expect(FramePreset.golden.aspect, closeTo(1.618, 0.001));
    });
  });
}
