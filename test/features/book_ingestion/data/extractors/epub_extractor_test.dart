import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/features/book_ingestion/data/extractors/epub_extractor.dart';
import 'package:zapbook/features/book_ingestion/domain/enums/ingestion_stage.dart';

import '../../../../support/fake_cover_generator.dart';
import '../../../../support/fixture_builders.dart';
import '../../../../support/temp_files.dart';
import 'package:zapbook/zbf/zbf.dart';

void main() {
  final extractor = EpubExtractor(coverGenerator: const FakeCoverGenerator());

  test('maps xhtml elements to block types', () async {
    final file = await writeTempFixture('sample.epub', buildEpubBytes());

    final book = (await extractor.extract(file).toList()).last.result;

    expect(book, isNotNull);
    expect(book!.manifest.sourceFormat, BookSourceFormat.epub);
    expect(book.manifest.title, 'Sample EPUB Book');
    expect(book.manifest.author, 'John Writer');

    final blocks = book.chapters.first.pages.first.blocks;
    expect(blocks.whereType<HeadingBlock>(), isNotEmpty);
    expect(blocks.whereType<ParagraphBlock>(), isNotEmpty);
    expect(blocks.whereType<PullquoteBlock>(), hasLength(1));
    expect(blocks.whereType<ImageBlock>(), hasLength(1));
    expect(blocks.whereType<CaptionBlock>(), hasLength(1));
    expect(blocks.whereType<DividerBlock>(), hasLength(1));
  });

  test('treats each spine item as a chapter', () async {
    final file = await writeTempFixture('sample.epub', buildEpubBytes());

    final book = (await extractor.extract(file).toList()).last.result;

    expect(book!.chapters, hasLength(2));
    expect(book.chapters.first.title, 'The Forest');
    expect(book.chapters[1].title, 'The River');
  });

  test('captures inline bold, italic and code as styled runs', () async {
    final file = await writeTempFixture('sample.epub', buildEpubBytes());

    final book = (await extractor.extract(file).toList()).last.result;
    final paragraph = book!.chapters.first.pages.first.blocks
        .whereType<ParagraphBlock>()
        .first;

    final runs = paragraph.runs ?? const <TextRun>[];
    expect(runs, isNotEmpty);
    expect(runs.any((run) => run.bold && run.text == 'deep'), isTrue);
    expect(runs.any((run) => run.italic && run.text == 'ancient'), isTrue);
    expect(runs.any((run) => run.code && run.text == 'wood'), isTrue);
  });

  test('maps a pre block to a code block with language', () async {
    final file = await writeTempFixture('sample.epub', buildEpubBytes());

    final book = (await extractor.extract(file).toList()).last.result;
    final code = book!.chapters[1].pages.first.blocks
        .whereType<CodeBlock>()
        .first;

    expect(code.text, contains('void main()'));
    expect(code.language, 'dart');
  });

  test('extracts referenced images into assets', () async {
    final file = await writeTempFixture('sample.epub', buildEpubBytes());

    final book = (await extractor.extract(file).toList()).last.result;
    final image = book!.chapters.first.pages.first.blocks
        .whereType<ImageBlock>()
        .first;

    expect(book.assets.containsKey(image.assetRef), isTrue);
    expect(image.altText, 'A tall tree');
  });

  test('streams progress per chapter between 0 and 1', () async {
    final file = await writeTempFixture('sample.epub', buildEpubBytes());

    final progress = await extractor.extract(file).toList();

    expect(progress.last.stage, IngestionStage.complete);
    for (final value in progress) {
      expect(value.progress, inInclusiveRange(0.0, 1.0));
    }
  });
}
