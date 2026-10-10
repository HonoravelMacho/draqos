import 'package:flutter/material.dart';
import 'tokens.dart';

/// Sci-Fi slider: neon track with notched rail.
class DraqSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String label;

  const DraqSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.label = '',
  });

  @override
  Widget build(BuildContext context) {
    final t = DraqosTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty)
          Text(
            label.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontSize: 11),
          ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: t.neonCyan,
            inactiveTrackColor: t.hullLight,
            thumbColor: t.neonCyan,
            overlayColor: t.neonCyan.withValues(alpha: 0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// Segmented option selector (used for shapes / presets).
class DraqSegmented<T> extends StatelessWidget {
  final List<T> options;
  final T value;
  final ValueChanged<T> onChanged;
  final String Function(T) labelOf;

  const DraqSegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.labelOf,
  });

  @override
  Widget build(BuildContext context) {
    final t = DraqosTokens.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          GestureDetector(
            onTap: () => onChanged(o),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: o == value
                    ? t.neonCyan.withValues(alpha: 0.18)
                    : t.hullDark,
                border: Border.all(
                  color: o == value ? t.neonCyan : t.hullLight,
                ),
              ),
              child: Text(
                labelOf(o).toUpperCase(),
                style: TextStyle(
                  color: o == value ? t.neonCyan : t.textDim,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
