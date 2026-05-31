import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/features/book_ingestion/data/extractors/txt_extractor.dart';
import 'package:zapbook/features/book_ingestion/domain/entities/ingestion_progress.dart';
import 'package:zapbook/features/book_ingestion/domain/enums/ingestion_stage.dart';

import '../../../../support/fake_cover_generator.dart';
import '../../../../support/fixture_builders.dart';
import '../../../../support/temp_files.dart';
import 'package:zapbook/zbf/zbf.dart';

void main() {
  final extractor = TxtExtractor(coverGenerator: const FakeCoverGenerator());

  test('splits chapters on heading lines and wraps paragraphs', () async {
    final file = await writeTempFixture('sample.txt', utf8.encode(sampleTxt));

    final progress = await extractor.extract(file).toList();
    final book = progress.last.result;

    expect(book, isNotNull);
    expect(book!.manifest.sourceFormat, BookSourceFormat.txt);
    expect(book.manifest.needsAiProcessing, isFalse);
    expect(book.chapters, hasLength(2));
    expect(book.chapters.first.title, 'Chapter 1');
    expect(book.chapters.first.pages.first.blocks.first, isA<HeadingBlock>());
    expect(
      book.chapters.first.pages.first.blocks.whereType<ParagraphBlock>(),
      hasLength(2),
    );
    expect(book.chapters[1].title, 'Chapter 2');
  });

  test('emits ordered stages with progress between 0 and 1', () async {
    final file = await writeTempFixture('sample.txt', utf8.encode(sampleTxt));

    final progress = await extractor.extract(file).toList();

    expect(progress.first.stage, IngestionStage.fileSelected);
    expect(progress.last.stage, IngestionStage.complete);
    for (final value in progress) {
      expect(value.progress, inInclusiveRange(0.0, 1.0));
    }
    expect(
      progress.map((p) => p.stage),
      containsAll(<IngestionStage>[
        IngestionStage.extracting,
        IngestionStage.assembling,
      ]),
    );
  });

  test('produces only a generated cover asset', () async {
    final file = await writeTempFixture('sample.txt', utf8.encode(sampleTxt));

    final IngestionProgress last =
        (await extractor.extract(file).toList()).last;

    expect(last.result!.assets.keys, ['cover.png']);
  });
}
