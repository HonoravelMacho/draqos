import 'package:flutter/material.dart';
import 'tokens.dart';

/// Cut-corner path used by every Sci-Fi surface.
Path cutCornerPath(Size size, double cut) {
  final c = cut.clamp(0.0, 40.0);
  return Path()
    ..moveTo(0, c)
    ..lineTo(c, 0)
    ..lineTo(size.width - c, 0)
    ..lineTo(size.width, c)
    ..lineTo(size.width, size.height - c)
    ..lineTo(size.width - c, size.height)
    ..lineTo(c, size.height)
    ..lineTo(0, size.height - c)
    ..close();
}

/// Metallic beveled panel with neon edge, corner brackets, inner
/// shadow and subtle scanlines. No native Material card look.
class DraqPanel extends StatelessWidget {
  final Widget child;
  final Color? accent;
  final EdgeInsetsGeometry padding;
  final bool glow;

  const DraqPanel({
    super.key,
    required this.child,
    this.accent,
    this.padding = const EdgeInsets.all(16),
    this.glow = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = DraqosTokens.of(context);
    final a = accent ?? t.neonCyan;
    return CustomPaint(
      painter: _PanelPainter(tokens: t, accent: a, glow: glow),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _PanelPainter extends CustomPainter {
  final DraqosTokens tokens;
  final Color accent;
  final bool glow;

  _PanelPainter(
      {required this.tokens, required this.accent, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final path = cutCornerPath(size, tokens.cornerCut);
    final b = tokens.bevel;

    // Drop shadow.
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.6), 8, false);

    // Hull gradient (brushed metal feel: diagonal gradient).
    final hullPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [tokens.hullLight, tokens.hull, tokens.hullDark],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, hullPaint);

    // Top bevel highlight.
    final bevelPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.center,
        colors: [
          Colors.white.withValues(alpha: 0.22),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & Size(size.width, b * 6));
    canvas.drawPath(
        Path()
          ..addPath(path, Offset.zero)
          ..addPath(
              cutCornerPath(
                  Size(size.width - b * 2, size.height - b * 2), tokens.cornerCut),
              Offset(b, b))
          ..fillType = PathFillType.evenOdd,
        bevelPaint);

    // Inner shadow (bottom).
    final innerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.center,
        colors: [Colors.black.withValues(alpha: 0.45), Colors.transparent],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, innerPaint);

    // Neon edge.
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = accent.withValues(alpha: 0.85);
    if (glow) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = accent.withValues(alpha: 0.25)
        ..maskFilter =
            MaskFilter.blur(BlurStyle.normal, tokens.glowRadius / 2);
      canvas.drawPath(path, glowPaint);
    }
    canvas.drawPath(path, edge);

    // Corner brackets.
    final bracket = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = accent;
    const bl = 14.0;
    final corners = [
      Offset(2, 2),
      Offset(size.width - 2, 2),
      Offset(2, size.height - 2),
      Offset(size.width - 2, size.height - 2),
    ];
    for (var i = 0; i < 4; i++) {
      final o = corners[i];
      final sx = i % 2 == 0 ? 1.0 : -1.0;
      final sy = i < 2 ? 1.0 : -1.0;
      canvas.drawPath(
          Path()
            ..moveTo(o.dx + bl * sx, o.dy)
            ..lineTo(o.dx, o.dy)
            ..lineTo(o.dx, o.dy + bl * sy),
          bracket);
    }

    // Scanlines.
    if (tokens.scanlineOpacity > 0) {
      final line = Paint()
        ..color = Colors.white.withValues(alpha: tokens.scanlineOpacity)
        ..strokeWidth = 1;
      canvas.save();
      canvas.clipPath(path);
      for (double y = 4; y < size.height; y += 5) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PanelPainter old) =>
      old.tokens != tokens || old.accent != accent || old.glow != glow;
}
