import 'package:injectable/injectable.dart';
import 'package:zapbook/core/domain/pdf_chunk_extractor.dart';
import 'package:zapbook/zbf/zbf.dart';

import 'package:zapbook/features/book_ingestion/data/cover/canvas_cover_generator.dart';
import 'package:zapbook/features/book_ingestion/data/cover/cover_generator.dart';
import 'package:zapbook/features/book_ingestion/data/extractors/book_extractor.dart';
import 'package:zapbook/features/book_ingestion/data/extractors/docx_extractor.dart';
import 'package:zapbook/features/book_ingestion/data/extractors/epub_extractor.dart';
import 'package:zapbook/features/book_ingestion/data/extractors/pdf_extractor.dart';
import 'package:zapbook/features/book_ingestion/data/extractors/txt_extractor.dart';

@module
abstract class IngestionModule {
  @lazySingleton
  CoverGenerator coverGenerator() => const CanvasCoverGenerator();

  @lazySingleton
  ZbfWriter zbfWriter() => const ZbfWriter();

  @lazySingleton
  ZbfReader zbfReader() => const ZbfReader();

  @lazySingleton
  PdfChunkExtractor pdfChunkExtractor(CoverGenerator cover) =>
      PdfExtractor(coverGenerator: cover);

  @lazySingleton
  List<BookExtractor> bookExtractors(CoverGenerator cover) => [
    PdfExtractor(coverGenerator: cover),
    DocxExtractor(coverGenerator: cover),
    EpubExtractor(coverGenerator: cover),
    TxtExtractor(coverGenerator: cover),
  ];
}
