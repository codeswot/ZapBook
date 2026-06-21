import 'dart:typed_data';

abstract interface class PdfPageRasterizer {
  Future<Uint8List?> render(
    String pdfFilePath,
    int pageIndex, {
    double dpi = 150,
  });
}
