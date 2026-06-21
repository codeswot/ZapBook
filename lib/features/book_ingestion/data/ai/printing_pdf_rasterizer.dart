import 'dart:io';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:printing/printing.dart';

import 'package:zapbook/core/domain/pdf_page_rasterizer.dart';

@LazySingleton(as: PdfPageRasterizer)
final class PrintingPdfRasterizer implements PdfPageRasterizer {
  const PrintingPdfRasterizer();

  @override
  Future<Uint8List?> render(
    String pdfFilePath,
    int pageIndex, {
    double dpi = 150,
  }) async {
    final pdfBytes = File(pdfFilePath).readAsBytesSync();
    await for (final page in Printing.raster(
      pdfBytes,
      pages: [pageIndex],
      dpi: dpi,
    )) {
      return page.toPng();
    }
    return null;
  }
}
