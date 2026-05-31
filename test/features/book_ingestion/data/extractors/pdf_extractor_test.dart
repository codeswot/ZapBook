import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/features/book_ingestion/data/extractors/pdf_extractor.dart';
import 'package:zapbook/features/book_ingestion/domain/enums/ingestion_stage.dart';

import '../../../../support/fake_cover_generator.dart';
import '../../../../support/fixture_builders.dart';
import '../../../../support/temp_files.dart';
import 'package:zapbook/zbf/zbf.dart';

void main() {
  final extractor = PdfExtractor(coverGenerator: const FakeCoverGenerator());

  test('reads metadata and page count', () async {
    final file = await writeTempFixture('sample.pdf', await buildPdfBytes());

    final book = (await extractor.extract(file).toList()).last.result;

    expect(book, isNotNull);
    expect(book!.manifest.sourceFormat, BookSourceFormat.pdf);
    expect(book.manifest.title, 'Sample PDF Book');
    expect(book.manifest.author, 'Ada Lovelace');
    expect(book.manifest.pageCount, 4);
  });

  test('detects chapter openers from heading-sized text', () async {
    final file = await writeTempFixture('sample.pdf', await buildPdfBytes());

    final book = (await extractor.extract(file).toList()).last.result;

    expect(book!.chapters, hasLength(2));
    expect(book.chapters.first.pages, hasLength(2));
    expect(book.chapters[1].pages, hasLength(2));
    expect(
      book.chapters.first.pages.first.layoutType,
      BookLayoutType.chapterOpener,
    );
    expect(book.chapters.first.pages.first.blocks.first, isA<HeadingBlock>());
  });

  test('groups monospace text into a code block', () async {
    final file = await writeTempFixture('sample.pdf', await buildPdfBytes());

    final book = (await extractor.extract(file).toList()).last.result;
    final blocks = book!.chapters
        .expand((chapter) => chapter.pages)
        .expand((page) => page.blocks);
    final code = blocks.whereType<CodeBlock>();

    expect(code, isNotEmpty);
    expect(code.first.text, contains('fn main()'));
  });

  test('keeps text-dense pages off the AI processing path', () async {
    final file = await writeTempFixture('sample.pdf', await buildPdfBytes());

    final book = (await extractor.extract(file).toList()).last.result;

    expect(book!.manifest.needsAiProcessing, isFalse);
  });

  test('streams per-page progress between 0 and 1', () async {
    final file = await writeTempFixture('sample.pdf', await buildPdfBytes());

    final progress = await extractor.extract(file).toList();

    expect(progress.last.stage, IngestionStage.complete);
    for (final value in progress) {
      expect(value.progress, inInclusiveRange(0.0, 1.0));
    }
  });
}
