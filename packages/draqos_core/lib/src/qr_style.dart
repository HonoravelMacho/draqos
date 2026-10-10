import 'dart:convert';

/// Serializable artistic style of a QR code (static or dynamic).
/// Field values are intentionally primitive so the style survives a
/// JSON round-trip and stays re-editable from any client.
class QrStyle {
  final String foregroundHex;
  final String backgroundHex;
  final String? backgroundImageBase64;
  final FramePreset framePreset;
  final double frameAspect;
  final ModuleShape moduleShape;
  final EyeOuterShape eyeOuterShape;
  final EyeInnerShape eyeInnerShape;
  final String eyeOuterHex;
  final String eyeInnerHex;
  final bool autoContrast;
  final double autoContrastMin;
  final String? centerIconBase64;
  final bool iconInvadeTransparent;
  final int quietZoneModules;

  const QrStyle({
    this.foregroundHex = '#111111',
    this.backgroundHex = '#FFFFFF',
    this.backgroundImageBase64,
    this.framePreset = FramePreset.square,
    this.frameAspect = 1.0,
    this.moduleShape = ModuleShape.square,
    this.eyeOuterShape = EyeOuterShape.square,
    this.eyeInnerShape = EyeInnerShape.square,
    this.eyeOuterHex = '#111111',
    this.eyeInnerHex = '#111111',
    this.autoContrast = false,
    this.autoContrastMin = 3.0,
    this.centerIconBase64,
    this.iconInvadeTransparent = false,
    this.quietZoneModules = 4,
  });

  Map<String, dynamic> toJson() => {
    'foregroundHex': foregroundHex,
    'backgroundHex': backgroundHex,
    'backgroundImageBase64': backgroundImageBase64,
    'framePreset': framePreset.name,
    'frameAspect': frameAspect,
    'moduleShape': moduleShape.name,
    'eyeOuterShape': eyeOuterShape.name,
    'eyeInnerShape': eyeInnerShape.name,
    'eyeOuterHex': eyeOuterHex,
    'eyeInnerHex': eyeInnerHex,
    'autoContrast': autoContrast,
    'autoContrastMin': autoContrastMin,
    'centerIconBase64': centerIconBase64,
    'iconInvadeTransparent': iconInvadeTransparent,
    'quietZoneModules': quietZoneModules,
  };

  factory QrStyle.fromJson(Map<String, dynamic> json) => QrStyle(
    foregroundHex: json['foregroundHex'] as String? ?? '#111111',
    backgroundHex: json['backgroundHex'] as String? ?? '#FFFFFF',
    backgroundImageBase64: json['backgroundImageBase64'] as String?,
    framePreset:
        FramePreset.values.asNameMap()[json['framePreset']] ??
        FramePreset.square,
    frameAspect: (json['frameAspect'] as num?)?.toDouble() ?? 1.0,
    moduleShape:
        ModuleShape.values.asNameMap()[json['moduleShape']] ??
        ModuleShape.square,
    eyeOuterShape:
        EyeOuterShape.values.asNameMap()[json['eyeOuterShape']] ??
        EyeOuterShape.square,
    eyeInnerShape:
        EyeInnerShape.values.asNameMap()[json['eyeInnerShape']] ??
        EyeInnerShape.square,
    eyeOuterHex: json['eyeOuterHex'] as String? ?? '#111111',
    eyeInnerHex: json['eyeInnerHex'] as String? ?? '#111111',
    autoContrast: json['autoContrast'] as bool? ?? false,
    autoContrastMin: (json['autoContrastMin'] as num?)?.toDouble() ?? 3.0,
    centerIconBase64: json['centerIconBase64'] as String?,
    iconInvadeTransparent: json['iconInvadeTransparent'] as bool? ?? false,
    quietZoneModules: json['quietZoneModules'] as int? ?? 4,
  );

  String encode() => jsonEncode(toJson());

  static QrStyle decode(String raw) {
    if (raw.trim().isEmpty) return const QrStyle();
    return QrStyle.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}

enum FramePreset {
  square(1.0),
  heart(1.0),
  a4Landscape(1.414),
  golden(1.618),
  free(0.0);

  const FramePreset(this.aspect);
  final double aspect;
}

enum ModuleShape { square, rounded, heart }

enum EyeOuterShape { square, rounded, circle }

enum EyeInnerShape { square, rounded, circle }
