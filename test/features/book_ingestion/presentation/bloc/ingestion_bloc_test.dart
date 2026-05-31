import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/features/book_ingestion/data/extractors/txt_extractor.dart';
import 'package:zapbook/features/book_ingestion/domain/entities/ingestion_progress.dart';
import 'package:zapbook/features/book_ingestion/domain/repositories/book_ingestion_repository.dart';
import 'package:zapbook/features/book_ingestion/domain/usecases/ingest_book.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/ingestion_bloc.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/ingestion_event.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/ingestion_state.dart';

import '../../../../support/fake_cover_generator.dart';
import '../../../../support/fixture_builders.dart';
import '../../../../support/temp_files.dart';
import 'package:zapbook/zbf/zbf.dart';

class _MockRepository extends Mock implements BookIngestionRepository {}

void main() {
  setUpAll(() => registerFallbackValue(File('fallback')));

  late _MockRepository repository;
  late ZbfBook book;

  setUp(() async {
    repository = _MockRepository();
    final extractor = TxtExtractor(coverGenerator: const FakeCoverGenerator());
    final file = await writeTempFixture('sample.txt', utf8.encode(sampleTxt));
    book = (await extractor.extract(file).toList()).last.result!;
  });

  blocTest<IngestionBloc, IngestionState>(
    'emits in-progress updates then complete',
    build: () {
      when(() => repository.ingest(any())).thenAnswer(
        (_) => Stream.fromIterable([
          IngestionProgress.extracting(progress: 0.5, currentItem: 'Page 1'),
          IngestionProgress.written(result: book, zbfPath: '/tmp/book.zbf'),
        ]),
      );
      return IngestionBloc(ingestBook: IngestBook(repository));
    },
    act: (bloc) => bloc.add(IngestionStarted(File('book.txt'))),
    expect: () => [
      isA<IngestionInProgress>(),
      isA<IngestionInProgress>(),
      isA<IngestionComplete>().having(
        (state) => state.zbfPath,
        'zbfPath',
        '/tmp/book.zbf',
      ),
    ],
  );

  blocTest<IngestionBloc, IngestionState>(
    'maps an AI-flagged result to the needs-processing state',
    build: () {
      final flagged = book.copyWith(
        manifest: book.manifest.copyWith(needsAiProcessing: true),
      );
      when(() => repository.ingest(any())).thenAnswer(
        (_) => Stream.fromIterable([
          IngestionProgress.written(result: flagged, zbfPath: '/tmp/ai.zbf'),
        ]),
      );
      return IngestionBloc(ingestBook: IngestBook(repository));
    },
    act: (bloc) => bloc.add(IngestionStarted(File('book.pdf'))),
    expect: () => [
      isA<IngestionInProgress>(),
      isA<IngestionNeedsAiProcessing>().having(
        (state) => state.zbfPath,
        'zbfPath',
        '/tmp/ai.zbf',
      ),
    ],
  );

  blocTest<IngestionBloc, IngestionState>(
    'emits failure carrying the last active stage',
    build: () {
      when(() => repository.ingest(any())).thenAnswer(
        (_) => Stream.fromIterable([
          IngestionProgress.extracting(progress: 0.2, currentItem: 'Page 1'),
          IngestionProgress.failed('boom'),
        ]),
      );
      return IngestionBloc(ingestBook: IngestBook(repository));
    },
    act: (bloc) => bloc.add(IngestionStarted(File('book.txt'))),
    expect: () => [
      isA<IngestionInProgress>(),
      isA<IngestionInProgress>(),
      isA<IngestionFailed>().having((state) => state.error, 'error', 'boom'),
    ],
  );

  blocTest<IngestionBloc, IngestionState>(
    'returns to idle when cancelled mid-stream',
    build: () {
      final controller = StreamController<IngestionProgress>();
      when(() => repository.ingest(any())).thenAnswer((_) => controller.stream);
      return IngestionBloc(ingestBook: IngestBook(repository));
    },
    act: (bloc) async {
      bloc.add(IngestionStarted(File('book.txt')));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const IngestionCancelled());
    },
    expect: () => [isA<IngestionInProgress>(), isA<IngestionIdle>()],
  );
}
