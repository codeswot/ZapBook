import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/features/book_ingestion/data/book_ingestion_repository_impl.dart';
import 'package:zapbook/features/book_ingestion/data/extractors/txt_extractor.dart';
import 'package:zapbook/features/book_ingestion/domain/enums/ingestion_stage.dart';

import '../../../support/fake_cover_generator.dart';
import '../../../support/fixed_documents_directory.dart';
import '../../../support/fixture_builders.dart';
import '../../../support/temp_files.dart';

void main() {
  late Directory documents;
  late BookIngestionRepositoryImpl repository;

  setUp(() async {
    documents = await createTempDirectory();
    repository = BookIngestionRepositoryImpl(
      extractors: [TxtExtractor(coverGenerator: const FakeCoverGenerator())],
      documentsDirectory: FixedDocumentsDirectory(documents),
    );
  });

  test('ingests a supported file and writes a zbf to documents', () async {
    final file = await writeTempFixture('sample.txt', utf8.encode(sampleTxt));

    final progress = await repository.ingest(file).toList();
    final last = progress.last;

    expect(last.stage, IngestionStage.complete);
    expect(last.zbfPath, isNotNull);
    expect(File(last.zbfPath ?? '').existsSync(), isTrue);
  });

  test('lists ingested books from the documents directory', () async {
    final file = await writeTempFixture('sample.txt', utf8.encode(sampleTxt));
    await repository.ingest(file).drain<void>();

    final books = await repository.getIngestedBooks();

    expect(books, hasLength(1));
    expect(books.first.sourceFormat.wireValue, 'txt');
  });

  test('reports failure for an unsupported file', () async {
    final file = await writeTempFixture('notes.rtf', utf8.encode('hello'));

    final progress = await repository.ingest(file).toList();

    expect(progress.single.stage, IngestionStage.error);
    expect(progress.single.error, contains('Unsupported'));
  });
}
