import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/features/book_ingestion/domain/entities/ingestion_progress.dart';
import 'package:zapbook/features/book_ingestion/domain/repositories/book_ingestion_repository.dart';
import 'package:zapbook/features/book_ingestion/domain/usecases/get_ingested_books.dart';
import 'package:zapbook/features/book_ingestion/domain/usecases/ingest_book.dart';

class _MockRepository extends Mock implements BookIngestionRepository {}

void main() {
  setUpAll(() => registerFallbackValue(File('fallback')));

  late _MockRepository repository;

  setUp(() => repository = _MockRepository());

  test('ingest use case forwards the repository stream', () async {
    final progress = [
      IngestionProgress.extracting(progress: 0.5, currentItem: 'Page 1'),
      IngestionProgress.failed('done'),
    ];
    when(
      () => repository.ingest(any()),
    ).thenAnswer((_) => Stream.fromIterable(progress));

    final result = await IngestBook(repository)(File('book.txt')).toList();

    expect(result, progress);
    verify(() => repository.ingest(any())).called(1);
  });

  test('get ingested books use case delegates to the repository', () async {
    when(() => repository.getIngestedBooks()).thenAnswer((_) async => const []);

    final result = await GetIngestedBooks(repository)();

    expect(result, isEmpty);
    verify(() => repository.getIngestedBooks()).called(1);
  });
}
