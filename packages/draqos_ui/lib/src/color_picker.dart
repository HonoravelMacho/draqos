import 'package:flutter/material.dart';
import 'tokens.dart';

/// Compact custom color picker in-theme: hue bar + hex field + swatches.
/// (Deliberately self-built so no native/default picker look leaks in.)
class DraqColorPicker extends StatefulWidget {
  final Color value;
  final ValueChanged<Color> onChanged;
  final String label;

  const DraqColorPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = '',
  });

  @override
  State<DraqColorPicker> createState() => _DraqColorPickerState();
}

class _DraqColorPickerState extends State<DraqColorPicker> {
  late TextEditingController _hex;

  static const _swatches = [
    Colors.black,
    Colors.white,
    Color(0xFF35F1FF),
    Color(0xFFFF3DF0),
    Color(0xFFFFB02E),
    Color(0xFF4DFF9E),
    Color(0xFFFF4D5E),
    Color(0xFF2B6BFF),
  ];

  @override
  void initState() {
    super.initState();
    _hex = TextEditingController(text: _toHex(widget.value));
  }

  @override
  void didUpdateWidget(covariant DraqColorPicker old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _hex.text = _toHex(widget.value);
  }

  static String _toHex(Color c) =>
      '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  void _fromHex(String raw) {
    var h = raw.trim().replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    final v = int.tryParse(h, radix: 16);
    if (v != null) widget.onChanged(Color(v));
  }

  @override
  Widget build(BuildContext context) {
    final t = DraqosTokens.of(context);
    final hsv = HSVColor.fromColor(widget.value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label.isNotEmpty)
          Text(widget.label.toUpperCase(),
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontSize: 11)),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.value,
                border: Border.all(color: t.neonCyan, width: 1.5),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _hex,
                onSubmitted: _fromHex,
                style: TextStyle(color: t.textMain, fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: t.hullDark,
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: t.hullLight)),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: t.hullLight)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Hue bar.
        GestureDetector(
          onPanUpdate: (d) => _pickHue(context, d.localPosition.dx),
          onTapDown: (d) => _pickHue(context, d.localPosition.dx),
          child: Container(
            height: 16,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                for (var h = 0; h <= 360; h += 30)
                  HSVColor.fromAHSV(1, h.toDouble(), 1, 1).toColor(),
              ]),
              border: Border.all(color: t.hullLight),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: [
            for (final s in _swatches)
              GestureDetector(
                onTap: () => widget.onChanged(s),
                child: Container(
                  width: 24,
                  height: 24,
                  color: s,
                ),
              ),
            // Alpha slider (cheap: opacity control).
            SizedBox(
              width: 120,
              child: Slider(
                value: widget.value.a,
                min: 0,
                max: 1,
                activeColor: t.neonMagenta,
                onChanged: (v) => widget.onChanged(widget.value.withValues(alpha: v)),
              ),
            ),
          ],
        ),
        // Saturation/value pad (simple): vertical value slider.
        Slider(
          value: hsv.saturation,
          min: 0,
          max: 1,
          activeColor: t.neonAmber,
          onChanged: (v) => widget.onChanged(
              hsv.withSaturation(v.clamp(0.0, 1.0)).toColor()),
        ),
      ],
    );
  }

  void _pickHue(BuildContext context, double dx) {
    final width = context.size?.width ?? 300;
    final hue = (dx / width * 360).clamp(0.0, 360.0);
    final hsv = HSVColor.fromColor(widget.value);
    widget.onChanged(hsv.withHue(hue).toColor());
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }
}
