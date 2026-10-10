import 'package:flutter/material.dart';
import 'tokens.dart';
import 'panel.dart';

/// Hexagonal-ish Sci-Fi button with pressed/hover/disabled states.
/// Rendered with CustomPainter — never a native Material button look.
class DraqButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? accent;
  final bool primary;

  const DraqButton({
    super.key,
    required this.label,
    this.onPressed,
    this.accent,
    this.primary = true,
  });

  @override
  State<DraqButton> createState() => _DraqButtonState();
}

class _DraqButtonState extends State<DraqButton> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = DraqosTokens.of(context);
    final enabled = widget.onPressed != null;
    final accent = widget.accent ?? t.neonCyan;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.45,
          child: CustomPaint(
            painter: _ButtonPainter(
              tokens: t,
              accent: accent,
              hover: _hover && enabled,
              pressed: _pressed && enabled,
              primary: widget.primary,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
              child: Text(
                widget.label.toUpperCase(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: enabled ? accent : t.textDim,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonPainter extends CustomPainter {
  final DraqosTokens tokens;
  final Color accent;
  final bool hover;
  final bool pressed;
  final bool primary;

  _ButtonPainter({
    required this.tokens,
    required this.accent,
    required this.hover,
    required this.pressed,
    required this.primary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = cutCornerPath(size, 8);
    final base = primary ? tokens.hullLight : tokens.hull;
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: pressed ? [tokens.hullDark, base] : [base, tokens.hullDark],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, fill);

    if (hover || pressed) {
      canvas.drawPath(path, Paint()..color = accent.withValues(alpha: 0.14));
    }
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hover ? 2.2 : 1.4
      ..color = accent.withValues(alpha: hover ? 1.0 : 0.7);
    if (!tokens.reduceMotion && (hover || pressed)) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = accent.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    canvas.drawPath(path, edge);

    // Top light strip.
    canvas.drawLine(
      Offset(10, 1.5),
      Offset(size.width - 10, 1.5),
      Paint()
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: pressed ? 0.08 : 0.28),
    );
  }

  @override
  bool shouldRepaint(covariant _ButtonPainter old) =>
      old.hover != hover || old.pressed != pressed || old.accent != accent;
}
