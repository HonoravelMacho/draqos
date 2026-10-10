import 'package:qr/qr.dart';

/// Functional QR matrix built with error-correction level H
/// (required: leaves room for the center icon + quiet zone).
class QrMatrix {
  final int size;
  final List<List<bool>> dark;
  final String data;

  QrMatrix._(this.data, this.size, this.dark);

  factory QrMatrix.build(String data) {
    final code = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.H,
    );
    final img = QrImage(code);
    final n = img.moduleCount;
    final dark = List.generate(
      n,
      (r) => List.generate(n, (c) => img.isDark(r, c)),
    );
    return QrMatrix._(data, n, dark);
  }

  bool isDark(int row, int col) => dark[row][col];

  /// True inside the three 7x7 finder (eye) regions.
  bool isFinder(int row, int col) {
    bool inBox(int r0, int c0) =>
        row >= r0 && row < r0 + 7 && col >= c0 && col < c0 + 7;
    return inBox(0, 0) || inBox(size - 7, 0) || inBox(0, size - 7);
  }

  /// Dark-module count excluding finder regions (for export sanity).
  int get dataDarkCount {
    var n = 0;
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (!isFinder(r, c) && dark[r][c]) n++;
      }
    }
    return n;
  }
}
