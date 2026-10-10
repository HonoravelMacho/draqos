import 'dart:math' as math;
import 'dart:ui' show Color;

/// Parses `#RRGGBB` / `#AARRGGBB` (also without `#`).
Color hexToColor(String hex) {
  var h = hex.trim().replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  if (h.length != 8) {
    throw FormatException('Invalid hex color: $hex');
  }
  return Color(int.parse(h, radix: 16));
}

String colorToHex(Color c) =>
    '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

double _linearize(double ch) =>
    ch <= 0.03928 ? ch / 12.92 : math.pow((ch + 0.055) / 1.055, 2.4) as double;

/// Relative luminance 0..1 (WCAG).
double luminance(Color c) {
  final r = _linearize(c.r);
  final g = _linearize(c.g);
  final b = _linearize(c.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// WCAG contrast ratio 1..21.
double contrastRatio(Color a, Color b) {
  final l1 = luminance(a);
  final l2 = luminance(b);
  final hi = math.max(l1, l2);
  final lo = math.min(l1, l2);
  return (hi + 0.05) / (lo + 0.05);
}

/// Auto-contrast: pick a dark or light module color so the ratio
/// against the background luminance stays above [minRatio].
/// Returns [darkOption] or [lightOption].
Color autoModuleColor({
  required double bgLuminance,
  required Color darkOption,
  required Color lightOption,
  required double minRatio,
}) {
  Color pick(Color candidate) => candidate;
  final darkRatio = _ratioAgainstLum(luminance(darkOption), bgLuminance);
  final lightRatio = _ratioAgainstLum(luminance(lightOption), bgLuminance);
  final darkOk = darkRatio >= minRatio;
  final lightOk = lightRatio >= minRatio;
  if (darkOk && lightOk) {
    // Prefer the option with the stronger contrast.
    return pick(darkRatio >= lightRatio ? darkOption : lightOption);
  }
  if (darkOk) return pick(darkOption);
  if (lightOk) return pick(lightOption);
  // Neither passes: return the stronger of the two (documented fallback).
  return pick(darkRatio >= lightRatio ? darkOption : lightOption);
}

double _ratioAgainstLum(double l1, double l2) {
  final hi = math.max(l1, l2);
  final lo = math.min(l1, l2);
  return (hi + 0.05) / (lo + 0.05);
}
