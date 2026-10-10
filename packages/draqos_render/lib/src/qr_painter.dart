import 'dart:ui' as ui;
import 'package:draqos_core/draqos_core.dart';
import 'package:flutter/widgets.dart';
import 'render_model.dart';

/// Geometry of one render: board (decorative frame) + QR square inside.
/// The QR matrix always stays square, intact and legible; the frame is
/// pure decoration around it.
class QrLayout {
  final ui.Rect board;
  final ui.Rect qrArea;
  final double moduleUnit;
  final int quietZone;

  const QrLayout({
    required this.board,
    required this.qrArea,
    required this.moduleUnit,
    required this.quietZone,
  });

  factory QrLayout.compute(Size size, QrRenderModel model) {
    final aspect = model.frameAspect;
    double bw = size.width;
    double bh = bw / aspect;
    if (bh > size.height) {
      bh = size.height;
      bw = bh * aspect;
    }
    final board = ui.Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: bw,
      height: bh,
    );
    // QR square centered with a decor margin (~7% each side).
    final side = (bw < bh ? bw : bh) * 0.86;
    final qrArea = ui.Rect.fromCenter(
      center: board.center,
      width: side,
      height: side,
    );
    final n = model.matrix.size;
    final qz = model.style.quietZoneModules;
    return QrLayout(
      board: board,
      qrArea: qrArea,
      moduleUnit: side / (n + 2 * qz),
      quietZone: qz,
    );
  }

  /// Top-left of module (row, col) including quiet-zone offset.
  Offset moduleOrigin(int row, int col) => Offset(
    qrArea.left + (col + quietZone) * moduleUnit,
    qrArea.top + (row + quietZone) * moduleUnit,
  );
}

/// Heart path filling [rect] (used for heart modules + heart frame).
Path heartPath(ui.Rect rect) {
  final w = rect.width;
  final h = rect.height;
  final x = rect.left;
  final y = rect.top;
  return Path()
    ..moveTo(x + 0.5 * w, y + 0.92 * h)
    ..cubicTo(
      x - 0.15 * w,
      y + 0.55 * h,
      x + 0.02 * w,
      y + 0.28 * h,
      x + 0.22 * w,
      y + 0.28 * h,
    )
    ..cubicTo(
      x + 0.36 * w,
      y + 0.28 * h,
      x + 0.44 * w,
      y + 0.36 * h,
      x + 0.5 * w,
      y + 0.44 * h,
    )
    ..cubicTo(
      x + 0.56 * w,
      y + 0.36 * h,
      x + 0.64 * w,
      y + 0.28 * h,
      x + 0.78 * w,
      y + 0.28 * h,
    )
    ..cubicTo(
      x + 0.98 * w,
      y + 0.28 * h,
      x + 1.15 * w,
      y + 0.55 * h,
      x + 0.5 * w,
      y + 0.92 * h,
    )
    ..close();
}

/// Sci-Fi QR painter: background (color/image over the whole frame),
/// shaped modules, configurable eyes, center icon, quiet zone.
class DraqQrPainter extends CustomPainter {
  final QrRenderModel model;
  final ui.Image? backgroundImage;
  final ui.Image? iconImage;

  DraqQrPainter({
    required this.model,
    this.backgroundImage,
    this.iconImage,
    super.repaint,
  });

  @override
  void paint(ui.Canvas canvas, Size size) {
    final layout = QrLayout.compute(size, model);
    // Full-bleed background first: keeps the QR (with quiet zone)
    // on a solid color even where a shaped board (e.g. heart notch)
    // does not cover. Readability always wins over decoration.
    canvas.drawRect(Offset.zero & size, Paint()..color = model.background);
    _paintBoard(canvas, size, layout);
    _paintModules(canvas, layout);
    _paintEyes(canvas, layout);
    _paintIcon(canvas, layout);
  }

  void _paintBoard(ui.Canvas canvas, Size size, QrLayout layout) {
    final style = model.style;
    Path boardPath;
    if (style.framePreset == FramePreset.heart) {
      boardPath = heartPath(layout.board);
    } else {
      boardPath = Path()..addRect(layout.board);
    }
    canvas.drawPath(boardPath, Paint()..color = model.background);
    final bg = backgroundImage;
    if (bg != null) {
      canvas.save();
      canvas.clipPath(boardPath);
      _drawCover(canvas, bg, layout.board);
      canvas.restore();
    }
    // Thin decor edge.
    canvas.drawPath(
      boardPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = model.foreground.withValues(alpha: 0.35),
    );
  }

  void _drawCover(ui.Canvas canvas, ui.Image img, ui.Rect dst) {
    final src = Rect.fromLTWH(
      0,
      0,
      img.width.toDouble(),
      img.height.toDouble(),
    );
    final wScale = dst.width / src.width;
    final hScale = dst.height / src.height;
    final scale = wScale > hScale ? wScale : hScale;
    final w = src.width * scale;
    final h = src.height * scale;
    final out = ui.Rect.fromCenter(center: dst.center, width: w, height: h);
    canvas.drawImageRect(
      img,
      src,
      out,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  void _paintModules(ui.Canvas canvas, QrLayout layout) {
    final m = model.matrix;
    final u = layout.moduleUnit;
    final batched = <Color, Path>{};
    Path pathFor(Color c) => batched.putIfAbsent(c, () => Path());

    for (var r = 0; r < m.size; r++) {
      for (var c = 0; c < m.size; c++) {
        if (!m.isDark(r, c) || m.isFinder(r, c)) continue;
        // Icon knockout is handled by the backdrop; skip icon zone only
        // when NOT invading so modules never peek through the icon box.
        if (!_invade() && _inIconZone(r, c)) continue;
        final o = layout.moduleOrigin(r, c);
        final rect = Rect.fromLTWH(o.dx, o.dy, u, u);
        final color = model.moduleColor(r, c);
        switch (model.style.moduleShape) {
          case ModuleShape.square:
            pathFor(color).addRect(rect);
          case ModuleShape.rounded:
            pathFor(color).addRRect(
              RRect.fromRectXY(rect.deflate(u * 0.08), u * 0.45, u * 0.45),
            );
          case ModuleShape.heart:
            // Extra separation: touching hearts mis-sample as blobs.
            pathFor(
              color,
            ).addPath(heartPath(rect.deflate(u * 0.12)), Offset.zero);
        }
      }
    }
    for (final e in batched.entries) {
      canvas.drawPath(e.value, Paint()..color = e.key);
    }
  }

  bool _invade() => model.style.iconInvadeTransparent;

  bool _inIconZone(int row, int col) {
    if (iconImage == null) return false;
    final n = model.matrix.size;
    final frac = model.iconFraction;
    final half = n * frac / 2;
    final center = (n - 1) / 2.0;
    return (row - center).abs() <= half && (col - center).abs() <= half;
  }

  void _paintEyes(ui.Canvas canvas, QrLayout layout) {
    final n = model.matrix.size;
    final origins = [
      [0, 0],
      [n - 7, 0],
      [0, n - 7],
    ];
    for (final o in origins) {
      _paintEye(canvas, layout, o[0], o[1]);
    }
  }

  void _paintEye(ui.Canvas canvas, QrLayout layout, int r0, int c0) {
    final u = layout.moduleUnit;
    final o = layout.moduleOrigin(r0, c0);
    final outer = Rect.fromLTWH(o.dx, o.dy, u * 7, u * 7);
    // Outer shape.
    final outerPath = _eyePath(outer, model.style.eyeOuterShape, true);
    canvas.drawPath(outerPath, Paint()..color = model.eyeOuter);
    // Separator punch (background).
    final mid = Rect.fromLTWH(o.dx + u, o.dy + u, u * 5, u * 5);
    canvas.drawPath(
      _eyePath(mid, model.style.eyeOuterShape, false),
      Paint()..color = model.background,
    );
    // Inner 3x3.
    final inner = Rect.fromLTWH(o.dx + u * 2, o.dy + u * 2, u * 3, u * 3);
    canvas.drawPath(
      _eyePath(inner, model.style.eyeInnerShape, true),
      Paint()..color = model.eyeInner,
    );
  }

  Path _eyePath(ui.Rect rect, Object shape, bool filled) {
    final kind = shape.toString();
    if (kind.endsWith('circle')) {
      if (!filled) {
        return Path()
          ..addOval(rect)
          ..fillType = PathFillType.evenOdd
          ..addOval(rect.deflate(rect.width * 0.18));
      }
      return Path()..addOval(rect);
    }
    if (kind.endsWith('rounded')) {
      final rr = RRect.fromRectXY(rect, rect.width * 0.25, rect.width * 0.25);
      return Path()..addRRect(rr);
    }
    return Path()..addRect(rect);
  }

  void _paintIcon(ui.Canvas canvas, QrLayout layout) {
    final icon = iconImage;
    if (icon == null) return;
    final side = layout.qrArea.width * model.iconFraction;
    final rect = ui.Rect.fromCenter(
      center: layout.qrArea.center,
      width: side,
      height: side,
    );
    if (!_invade()) {
      // Knockout backdrop so the icon zone never breaks readability.
      final pad = layout.moduleUnit * 0.8;
      canvas.drawRRect(
        RRect.fromRectXY(rect.inflate(pad), 6, 6),
        Paint()..color = model.background,
      );
    }
    _drawContain(canvas, icon, rect);
  }

  void _drawContain(ui.Canvas canvas, ui.Image img, ui.Rect dst) {
    final src = Rect.fromLTWH(
      0,
      0,
      img.width.toDouble(),
      img.height.toDouble(),
    );
    final wScale = dst.width / src.width;
    final hScale = dst.height / src.height;
    final scale = wScale < hScale ? wScale : hScale;
    final out = ui.Rect.fromCenter(
      center: dst.center,
      width: src.width * scale,
      height: src.height * scale,
    );
    canvas.drawImageRect(
      img,
      src,
      out,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant DraqQrPainter old) =>
      !identical(old.model, model) ||
      old.backgroundImage != backgroundImage ||
      old.iconImage != iconImage;

  @override
  bool? hitTest(Offset position) => false;
}
