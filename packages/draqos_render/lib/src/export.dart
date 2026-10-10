import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:draqos_core/draqos_core.dart';
import 'package:flutter/widgets.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'color_utils.dart';
import 'qr_painter.dart';
import 'render_model.dart';

/// Decode raw bytes (PNG/JPEG/SVG-rasterized) into a [ui.Image].
Future<ui.Image> decodeUiImage(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

/// Render [model] to PNG bytes.
Future<Uint8List> exportPng(
  QrRenderModel model, {
  int sizePx = 1024,
  ui.Image? backgroundImage,
  ui.Image? iconImage,
}) async {
  final aspect = model.frameAspect;
  final w = sizePx.toDouble();
  final h = (sizePx / aspect).roundToDouble();
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  DraqQrPainter(
    model: model,
    backgroundImage: backgroundImage,
    iconImage: iconImage,
  ).paint(canvas, Size(w, h));
  final picture = recorder.endRecording();
  final img = await picture.toImage(w.toInt(), h.toInt());
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

/// Build a standalone SVG string from [model].
/// Heart modules become `<path>` hearts; rounded become `<circle>`;
/// eyes are drawn with their configured shapes/colors.
String exportSvg(QrRenderModel model) {
  final m = model.matrix;
  final qz = model.style.quietZoneModules;
  final total = m.size + 2 * qz;
  final aspect = model.frameAspect;
  final w = total.toDouble();
  final h = (total / aspect);
  final buf = StringBuffer()
    ..writeln(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${w.toStringAsFixed(1)} ${h.toStringAsFixed(1)}" shape-rendering="crispEdges">',
    );
  final bgHex = colorToHex(model.background);
  final ox = (w - total) / 2; // board fills viewBox; qr centered vertically
  final oy = (h - total) / 2;
  buf.writeln('<rect width="$w" height="$h" fill="$bgHex"/>');
  final bg64 = model.style.backgroundImageBase64;
  if (bg64 != null && bg64.isNotEmpty) {
    buf.writeln(
      '<image href="data:image/png;base64,$bg64" x="0" y="0" width="$w" height="$h" preserveAspectRatio="xMidYMid slice"/>',
    );
  }

  void modRect(int r, int c, String fill) {
    final x = (ox + c + qz).toStringAsFixed(2);
    final y = (oy + r + qz).toStringAsFixed(2);
    switch (model.style.moduleShape) {
      case ModuleShape.square:
        buf.writeln('<rect x="$x" y="$y" width="1" height="1" fill="$fill"/>');
      case ModuleShape.rounded:
        buf.writeln(
          '<circle cx="${(ox + c + qz + 0.5).toStringAsFixed(2)}" cy="${(oy + r + qz + 0.5).toStringAsFixed(2)}" r="0.46" fill="$fill"/>',
        );
      case ModuleShape.heart:
        final cx = ox + c + qz;
        final cy = oy + r + qz;
        buf.writeln(
          '<path d="M ${(cx + 0.5).toStringAsFixed(2)} ${(cy + 0.92).toStringAsFixed(2)} '
          'C ${(cx - 0.15).toStringAsFixed(2)} ${(cy + 0.55).toStringAsFixed(2)} ${(cx + 0.02).toStringAsFixed(2)} ${(cy + 0.28).toStringAsFixed(2)} ${(cx + 0.22).toStringAsFixed(2)} ${(cy + 0.28).toStringAsFixed(2)} '
          'C ${(cx + 0.36).toStringAsFixed(2)} ${(cy + 0.28).toStringAsFixed(2)} ${(cx + 0.44).toStringAsFixed(2)} ${(cy + 0.36).toStringAsFixed(2)} ${(cx + 0.5).toStringAsFixed(2)} ${(cy + 0.44).toStringAsFixed(2)} '
          'C ${(cx + 0.56).toStringAsFixed(2)} ${(cy + 0.36).toStringAsFixed(2)} ${(cx + 0.64).toStringAsFixed(2)} ${(cy + 0.28).toStringAsFixed(2)} ${(cx + 0.78).toStringAsFixed(2)} ${(cy + 0.28).toStringAsFixed(2)} '
          'C ${(cx + 0.98).toStringAsFixed(2)} ${(cy + 0.28).toStringAsFixed(2)} ${(cx + 1.15).toStringAsFixed(2)} ${(cy + 0.55).toStringAsFixed(2)} ${(cx + 0.5).toStringAsFixed(2)} ${(cy + 0.92).toStringAsFixed(2)} Z" fill="$fill"/>',
        );
    }
  }

  final fg = colorToHex(model.foreground);
  for (var r = 0; r < m.size; r++) {
    for (var c = 0; c < m.size; c++) {
      if (!m.isDark(r, c) || m.isFinder(r, c)) continue;
      // Note: SVG uses the flat foreground color; per-region
      // auto-contrast applies to raster renders with a bg image.
      modRect(r, c, fg);
    }
  }
  // Eyes (7x7 outer + 3x3 inner; separator assumed background).
  final eyeO = colorToHex(model.eyeOuter);
  final eyeI = colorToHex(model.eyeInner);
  final origins = [
    [0, 0],
    [m.size - 7, 0],
    [0, m.size - 7],
  ];
  for (final o in origins) {
    final x = (ox + o[1] + qz).toStringAsFixed(2);
    final y = (oy + o[0] + qz).toStringAsFixed(2);
    buf.writeln('<rect x="$x" y="$y" width="7" height="7" fill="$eyeO"/>');
    buf.writeln(
      '<rect x="${(ox + o[1] + qz + 1).toStringAsFixed(2)}" y="${(oy + o[0] + qz + 1).toStringAsFixed(2)}" width="5" height="5" fill="$bgHex"/>',
    );
    buf.writeln(
      '<rect x="${(ox + o[1] + qz + 2).toStringAsFixed(2)}" y="${(oy + o[0] + qz + 2).toStringAsFixed(2)}" width="3" height="3" fill="$eyeI"/>',
    );
  }
  buf.writeln('</svg>');
  return buf.toString();
}

/// Render [model] to a one-page PDF.
Future<Uint8List> exportPdf(QrRenderModel model) async {
  final m = model.matrix;
  final qz = model.style.quietZoneModules;
  final total = (m.size + 2 * qz).toDouble();
  final aspect = model.frameAspect;
  final pageW = 400.0;
  final pageH = pageW / aspect;
  final unit = pageW / total;
  final doc = pw.Document();
  final fg = pdf.PdfColor.fromHex(colorToHex(model.foreground));
  final bg = pdf.PdfColor.fromHex(colorToHex(model.background));
  final eyeO = pdf.PdfColor.fromHex(colorToHex(model.eyeOuter));
  final eyeI = pdf.PdfColor.fromHex(colorToHex(model.eyeInner));
  doc.addPage(
    pw.Page(
      pageFormat: pdf.PdfPageFormat(pageW, pageH),
      build: (ctx) => pw.Stack(
        children: [
          pw.Positioned.fill(child: pw.Container(color: bg)),
          // Modules (heart approximated as filled circle in PDF).
          for (var r = 0; r < m.size; r++)
            for (var c = 0; c < m.size; c++)
              if (m.isDark(r, c) && !m.isFinder(r, c))
                pw.Positioned(
                  left: (c + qz) * unit,
                  top: (r + qz) * unit,
                  child: model.style.moduleShape == ModuleShape.square
                      ? pw.Container(width: unit, height: unit, color: fg)
                      : pw.Container(
                          width: unit,
                          height: unit,
                          decoration: pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            color: fg,
                          ),
                        ),
                ),
          // Eyes.
          for (final o in [
            [0, 0],
            [m.size - 7, 0],
            [0, m.size - 7],
          ]) ...[
            pw.Positioned(
              left: (o[1] + qz) * unit,
              top: (o[0] + qz) * unit,
              child: pw.Container(
                width: 7 * unit,
                height: 7 * unit,
                color: eyeO,
              ),
            ),
            pw.Positioned(
              left: (o[1] + qz + 1) * unit,
              top: (o[0] + qz + 1) * unit,
              child: pw.Container(width: 5 * unit, height: 5 * unit, color: bg),
            ),
            pw.Positioned(
              left: (o[1] + qz + 2) * unit,
              top: (o[0] + qz + 2) * unit,
              child: pw.Container(
                width: 3 * unit,
                height: 3 * unit,
                color: eyeI,
              ),
            ),
          ],
        ],
      ),
    ),
  );
  return doc.save();
}
