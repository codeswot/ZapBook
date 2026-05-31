import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/features/book_ingestion/data/extractors/docx_extractor.dart';
import 'package:zapbook/features/book_ingestion/domain/enums/ingestion_stage.dart';

import '../../../../support/fake_cover_generator.dart';
import '../../../../support/fixture_builders.dart';
import '../../../../support/temp_files.dart';
import 'package:zapbook/zbf/zbf.dart';

void main() {
  final extractor = DocxExtractor(coverGenerator: const FakeCoverGenerator());

  test('maps paragraph styles to block types', () async {
    final file = await writeTempFixture('sample.docx', buildDocxBytes());

    final book = (await extractor.extract(file).toList()).last.result;

    expect(book, isNotNull);
    expect(book!.manifest.sourceFormat, BookSourceFormat.docx);
    expect(book.manifest.title, 'Sample DOCX Book');
    expect(book.manifest.author, 'Jane Author');

    final firstChapter = book.chapters.first;
    final blocks = firstChapter.pages.first.blocks;
    expect(blocks.first, isA<HeadingBlock>());
    expect(blocks.whereType<PullquoteBlock>(), hasLength(1));
    expect(blocks.whereType<ImageBlock>(), hasLength(1));
  });

  test('captures bold runs from run properties', () async {
    final file = await writeTempFixture('sample.docx', buildDocxBytes());

    final book = (await extractor.extract(file).toList()).last.result;
    final paragraph = book!.chapters.first.pages.first.blocks
        .whereType<ParagraphBlock>()
        .first;

    final runs = paragraph.runs ?? const <TextRun>[];
    expect(runs, isNotEmpty);
    expect(runs.any((run) => run.bold && run.text == 'dark'), isTrue);
  });

  test('detects chapters on Heading1 boundaries', () async {
    final file = await writeTempFixture('sample.docx', buildDocxBytes());

    final book = (await extractor.extract(file).toList()).last.result;

    expect(book!.chapters, hasLength(2));
    expect(book.chapters.first.title, 'The Beginning');
    expect(book.chapters[1].title, 'The Middle');
  });

  test('extracts embedded media into assets with alt text', () async {
    final file = await writeTempFixture('sample.docx', buildDocxBytes());

    final book = (await extractor.extract(file).toList()).last.result;
    final image = book!.chapters.first.pages.first.blocks
        .whereType<ImageBlock>()
        .first;

    expect(book.assets.containsKey(image.assetRef), isTrue);
    expect(image.altText, 'A quiet forest');
  });

  test('streams progress between 0 and 1 ending complete', () async {
    final file = await writeTempFixture('sample.docx', buildDocxBytes());

    final progress = await extractor.extract(file).toList();

    expect(progress.last.stage, IngestionStage.complete);
    for (final value in progress) {
      expect(value.progress, inInclusiveRange(0.0, 1.0));
    }
  });
}
