import 'dart:typed_data';
import 'package:injectable/injectable.dart';
import 'package:zapbook/core/domain/pdf_chunk_extractor.dart';
import 'package:zapbook/core/domain/pdf_page_rasterizer.dart';
import 'package:zapbook/zbf/zbf.dart';

@injectable
class RasterizePdfPageUseCase {
  const RasterizePdfPageUseCase(this._rasterizer);

  final PdfPageRasterizer _rasterizer;

  Future<Uint8List?> call(
    String pdfFilePath,
    int pageIndex, {
    double dpi = 150,
  }) {
    return _rasterizer.render(pdfFilePath, pageIndex, dpi: dpi);
  }
}

@injectable
class ExtractPdfChunkUseCase {
  const ExtractPdfChunkUseCase(this._extractor);

  final PdfChunkExtractor _extractor;

  Future<List<BookPage>> call(
    String pdfFilePath,
    int startPageIndex,
    int endPageIndex,
    String chapterTitle,
    int chapterIndex,
  ) {
    return _extractor.extractRange(
      pdfFilePath,
      startPageIndex,
      endPageIndex,
      chapterTitle,
      chapterIndex,
    );
  }
}
