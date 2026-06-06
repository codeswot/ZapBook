import 'dart:typed_data';

import 'package:zapbook/zbf/zbf.dart';

abstract interface class PdfChunkExtractor {
  Future<List<BookPage>> extractRange(
    Uint8List bytes,
    int startPageIndex,
    int endPageIndex,
    String chapterTitle,
    int chapterIndex,
  );
}
