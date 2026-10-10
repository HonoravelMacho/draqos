import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

/// Decode QR payload from rendered PNG bytes (zxing2).
/// Shared by automated tests and the in-app "Testar leitura" button.
String decodeQrPng(Uint8List png) {
  final decoded = img.decodeImage(png);
  if (decoded == null) {
    throw FormatException('Could not decode PNG bytes');
  }
  final pixels = Int32List(decoded.width * decoded.height);
  var i = 0;
  for (var y = 0; y < decoded.height; y++) {
    for (var x = 0; x < decoded.width; x++) {
      final p = decoded.getPixel(x, y);
      pixels[i++] =
          0xFF000000 |
          ((p.r.toInt() & 0xFF) << 16) |
          ((p.g.toInt() & 0xFF) << 8) |
          (p.b.toInt() & 0xFF);
    }
  }
  final source = RGBLuminanceSource(decoded.width, decoded.height, pixels);
  final bitmap = BinaryBitmap(HybridBinarizer(source));
  return QRCodeReader().decode(bitmap).text;
}
