import 'package:zapbook/zbf/zbf.dart';

abstract interface class PdfChunkExtractor {
  Future<List<BookPage>> extractRange(
    String pdfFilePath,
    int startPageIndex,
    int endPageIndex,
    String chapterTitle,
    int chapterIndex,
  );
}
