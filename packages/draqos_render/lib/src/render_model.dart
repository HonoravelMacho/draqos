import 'dart:ui' show Color;
import 'package:draqos_core/draqos_core.dart';
import 'package:image/image.dart' as img;
import 'color_utils.dart';
import 'qr_matrix.dart';

/// Pure-Dart render plan: which color each module gets, eye colors,
/// frame geometry. The Flutter painter consumes this.
class QrRenderModel {
  final QrMatrix matrix;
  final QrStyle style;
  final Color foreground;
  final Color background;
  final Color eyeOuter;
  final Color eyeInner;

  /// Optional per-module background luminance sampled from the
  /// background image (row-major, size*size). Null = flat background.
  List<double>? bgLuminance;

  QrRenderModel({
    required this.matrix,
    required this.style,
    required this.foreground,
    required this.background,
    required this.eyeOuter,
    required this.eyeInner,
    this.bgLuminance,
  });

  factory QrRenderModel.fromData(String data, QrStyle style) {
    final matrix = QrMatrix.build(data);
    return QrRenderModel(
      matrix: matrix,
      style: style,
      foreground: hexToColor(style.foregroundHex),
      background: hexToColor(style.backgroundHex),
      eyeOuter: hexToColor(style.eyeOuterHex),
      eyeInner: hexToColor(style.eyeInnerHex),
    );
  }

  /// Sample [image] luminance per QR module (used for auto-contrast).
  /// The image is assumed to fill the whole QR area.
  void sampleBackground(img.Image image) {
    final n = matrix.size;
    bgLuminance = List<double>.filled(n * n, 0);
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        final px = (r + 0.5) / n * image.height;
        final py = (c + 0.5) / n * image.width;
        final p = image.getPixel(
          py.toInt().clamp(0, image.width - 1),
          px.toInt().clamp(0, image.height - 1),
        );
        final lum = (0.2126 * p.r + 0.7152 * p.g + 0.0722 * p.b) / 255.0;
        bgLuminance![r * n + c] = lum;
      }
    }
  }

  double _bgLumAt(int row, int col) {
    final grid = bgLuminance;
    if (grid == null) return luminance(background);
    return grid[row * matrix.size + col];
  }

  /// Module color honoring auto-contrast against the local background.
  Color moduleColor(int row, int col) {
    if (!style.autoContrast) return foreground;
    const dark = Color(0xFF0A0A0A);
    const light = Color(0xFFFFFFFF);
    return autoModuleColor(
      bgLuminance: _bgLumAt(row, col),
      darkOption: foreground.computeLuminance() < 0.5 ? foreground : dark,
      lightOption: light,
      minRatio: style.autoContrastMin,
    );
  }

  /// Frame aspect (width / height) resolved from the preset.
  double get frameAspect {
    if (style.framePreset == FramePreset.free) {
      return style.frameAspect <= 0 ? 1.0 : style.frameAspect;
    }
    return style.framePreset.aspect;
  }

  /// Relative icon box (fraction of QR side, centered).
  double get iconFraction => 0.24;
}
