import 'package:flutter/material.dart';

/// Single source of truth for the DRAQOS Sci-Fi look.
/// Everything visual reads from here so the whole design can be
/// swapped without touching client/server code.
@immutable
class DraqosTokens extends ThemeExtension<DraqosTokens> {
  final Color abyss;
  final Color hullDark;
  final Color hull;
  final Color hullLight;
  final Color neonCyan;
  final Color neonMagenta;
  final Color neonAmber;
  final Color textMain;
  final Color textDim;
  final Color danger;
  final Color success;
  final double cornerCut;
  final double bevel;
  final double glowRadius;
  final double scanlineOpacity;
  final bool reduceMotion;
  final String displayFont;
  final String bodyFont;

  const DraqosTokens({
    this.abyss = const Color(0xFF05070D),
    this.hullDark = const Color(0xFF0B1220),
    this.hull = const Color(0xFF131C31),
    this.hullLight = const Color(0xFF1E2A47),
    this.neonCyan = const Color(0xFF35F1FF),
    this.neonMagenta = const Color(0xFFFF3DF0),
    this.neonAmber = const Color(0xFFFFB02E),
    this.textMain = const Color(0xFFE8F4FF),
    this.textDim = const Color(0xFF8DA1C0),
    this.danger = const Color(0xFFFF4D5E),
    this.success = const Color(0xFF4DFF9E),
    this.cornerCut = 14.0,
    this.bevel = 3.0,
    this.glowRadius = 12.0,
    this.scanlineOpacity = 0.06,
    this.reduceMotion = false,
    this.displayFont = 'Orbitron',
    this.bodyFont = 'Rajdhani',
  });

  @override
  DraqosTokens copyWith({bool? reduceMotion, double? scanlineOpacity}) =>
      DraqosTokens(
        abyss: abyss,
        hullDark: hullDark,
        hull: hull,
        hullLight: hullLight,
        neonCyan: neonCyan,
        neonMagenta: neonMagenta,
        neonAmber: neonAmber,
        textMain: textMain,
        textDim: textDim,
        danger: danger,
        success: success,
        cornerCut: cornerCut,
        bevel: bevel,
        glowRadius: glowRadius,
        scanlineOpacity: scanlineOpacity ?? this.scanlineOpacity,
        reduceMotion: reduceMotion ?? this.reduceMotion,
        displayFont: displayFont,
        bodyFont: bodyFont,
      );

  @override
  DraqosTokens lerp(ThemeExtension<DraqosTokens>? other, double t) {
    if (other is! DraqosTokens) return this;
    return DraqosTokens(
      reduceMotion: t < 0.5 ? reduceMotion : other.reduceMotion,
      scanlineOpacity:
          scanlineOpacity + (other.scanlineOpacity - scanlineOpacity) * t,
    );
  }

  static DraqosTokens of(BuildContext context) =>
      Theme.of(context).extension<DraqosTokens>() ?? const DraqosTokens();
}

/// Builds the app-wide Sci-Fi ThemeData from tokens.
ThemeData draqosTheme({bool reduceMotion = false}) {
  const tokens = DraqosTokens();
  final scheme = ColorScheme.dark(
    primary: tokens.neonCyan,
    secondary: tokens.neonMagenta,
    tertiary: tokens.neonAmber,
    surface: tokens.hull,
    error: tokens.danger,
    onSurface: tokens.textMain,
  );
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: tokens.abyss,
    colorScheme: scheme,
    extensions: [tokens.copyWith(reduceMotion: reduceMotion)],
    textTheme: TextTheme(
      displayLarge: TextStyle(
        color: tokens.textMain,
        letterSpacing: 2.0,
        fontWeight: FontWeight.w800,
      ),
      bodyMedium: TextStyle(color: tokens.textDim, letterSpacing: 0.6),
      labelLarge: TextStyle(
        color: tokens.neonCyan,
        letterSpacing: 1.6,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
