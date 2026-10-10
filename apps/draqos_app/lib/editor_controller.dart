import 'dart:ui' as ui;

import 'package:draqos_core/draqos_core.dart';
import 'package:draqos_render/draqos_render.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image/image.dart' as img;

/// Editable state of the static-QR studio screen.
/// Composition-layer only: builds core/render objects, holds no
/// business logic.
class EditorController extends ChangeNotifier {
  String data = 'https://example.com';
  String foregroundHex = '#111111';
  String backgroundHex = '#FFFFFF';
  String eyeOuterHex = '#111111';
  String eyeInnerHex = '#111111';
  ModuleShape moduleShape = ModuleShape.square;
  EyeOuterShape eyeOuterShape = EyeOuterShape.square;
  EyeInnerShape eyeInnerShape = EyeInnerShape.square;
  FramePreset framePreset = FramePreset.square;
  double freeAspect = 1.3;
  double quietZone = 4;
  bool autoContrast = false;
  double autoContrastMin = 3.0;
  bool iconInvadeTransparent = false;

  ui.Image? backgroundImage;
  ui.Image? iconImage;
  String? backgroundName;
  String? iconName;

  img.Image? _bgSample;

  QrStyle buildStyle() => QrStyle(
    foregroundHex: foregroundHex,
    backgroundHex: backgroundHex,
    framePreset: framePreset,
    frameAspect: framePreset == FramePreset.free
        ? freeAspect
        : framePreset.aspect,
    moduleShape: moduleShape,
    eyeOuterShape: eyeOuterShape,
    eyeInnerShape: eyeInnerShape,
    eyeOuterHex: eyeOuterHex,
    eyeInnerHex: eyeInnerHex,
    autoContrast: autoContrast,
    autoContrastMin: autoContrastMin,
    iconInvadeTransparent: iconInvadeTransparent,
    quietZoneModules: quietZone.round(),
  );

  QrRenderModel buildModel() {
    final model = QrRenderModel.fromData(
      data.isEmpty ? 'https://example.com' : data,
      buildStyle(),
    );
    final sample = _bgSample;
    if (sample != null) model.sampleBackground(sample);
    return model;
  }

  void _touch() => notifyListeners();

  void setData(String v) {
    data = v;
    _touch();
  }

  void setForeground(String v) {
    foregroundHex = v;
    _touch();
  }

  void setBackground(String v) {
    backgroundHex = v;
    _touch();
  }

  void setEyeOuter(String v) {
    eyeOuterHex = v;
    _touch();
  }

  void setEyeInner(String v) {
    eyeInnerHex = v;
    _touch();
  }

  void setModuleShape(ModuleShape v) {
    moduleShape = v;
    _touch();
  }

  void setEyeOuterShape(EyeOuterShape v) {
    eyeOuterShape = v;
    _touch();
  }

  void setEyeInnerShape(EyeInnerShape v) {
    eyeInnerShape = v;
    _touch();
  }

  void setFramePreset(FramePreset v) {
    framePreset = v;
    _touch();
  }

  void setFreeAspect(double v) {
    freeAspect = v;
    _touch();
  }

  void setQuietZone(double v) {
    quietZone = v;
    _touch();
  }

  void setAutoContrast(bool v) {
    autoContrast = v;
    _touch();
  }

  void setIconInvade(bool v) {
    iconInvadeTransparent = v;
    _touch();
  }

  static Future<ui.Image> rasterize(Uint8List bytes) async {
    final lower = String.fromCharCodes(bytes.take(5)).toLowerCase();
    if (lower.contains('<svg') || bytes.length > 5 && _looksLikeSvg(bytes)) {
      final pic = await vg.loadPicture(SvgBytesLoader(bytes), null);
      final img = await pic.picture.toImage(512, 512);
      pic.picture.dispose();
      return img;
    }
    final codec = await ui.instantiateImageCodec(bytes);
    return (await codec.getNextFrame()).image;
  }

  static bool _looksLikeSvg(Uint8List bytes) {
    final head = String.fromCharCodes(bytes.take(200)).toLowerCase();
    return head.contains('<svg');
  }

  Future<bool> pickBackground() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: false,
    );
    if (res == null || res.files.first.bytes == null) return false;
    final bytes = res.files.first.bytes!;
    backgroundImage = await rasterize(bytes);
    _bgSample = img.decodeImage(bytes);
    backgroundName = res.files.first.name;
    _touch();
    return true;
  }

  Future<bool> pickIcon() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'svg'],
      withData: true,
      allowMultiple: false,
    );
    if (res == null || res.files.first.bytes == null) return false;
    iconImage = await rasterize(res.files.first.bytes!);
    iconName = res.files.first.name;
    _touch();
    return true;
  }

  void clearBackground() {
    backgroundImage = null;
    _bgSample = null;
    backgroundName = null;
    _touch();
  }

  void clearIcon() {
    iconImage = null;
    iconName = null;
    _touch();
  }

  /// Returns the decoded payload (throws when unreadable).
  Future<String> testRead() async {
    final model = buildModel();
    final png = await exportPng(
      model,
      sizePx: 800,
      backgroundImage: backgroundImage,
      iconImage: iconImage,
    );
    return decodeQrPng(png);
  }
}
