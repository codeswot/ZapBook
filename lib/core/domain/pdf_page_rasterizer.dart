import 'dart:typed_data';

abstract interface class PdfPageRasterizer {
  Future<Uint8List?> render(
    Uint8List pdfBytes,
    int pageIndex, {
    double dpi = 150,
  });
}
