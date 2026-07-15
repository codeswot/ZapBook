import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:zapbook/core/domain/book_ingestion_repository.dart';
import 'package:zapbook/core/domain/ingestion_progress.dart';
import 'package:zapbook/core/domain/ingestion_stage.dart';
import 'package:zapbook/core/domain/wizard_data.dart';

import 'package:zapbook/features/book_ingestion/domain/usecases/ingestion_orchestrator_usecases.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/ingestion_orchestrator_cubit.dart';
import 'package:zapbook/zbf/zbf.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';

class MockBookIngestionRepository extends Mock
    implements BookIngestionRepository {}

class MockCreateCircleBookUseCase extends Mock
    implements CreateCircleBookUseCase {}

class MockDeleteBookFilesUseCase extends Mock
    implements DeleteBookFilesUseCase {}

class MockFinalizeAndUploadBookUseCase extends Mock
    implements FinalizeAndUploadBookUseCase {}

class FakeFile extends Fake implements File {
  @override
  String get path => '/path/to/fake_file.pdf';
}

void main() {
  late MockBookIngestionRepository repository;
  late MockCreateCircleBookUseCase createCircleBook;
  late MockDeleteBookFilesUseCase deleteBookFiles;
  late MockFinalizeAndUploadBookUseCase finalizeAndUploadBook;
  late IngestionOrchestratorCubit cubit;

  setUp(() {
    repository = MockBookIngestionRepository();
    createCircleBook = MockCreateCircleBookUseCase();
    deleteBookFiles = MockDeleteBookFilesUseCase();
    finalizeAndUploadBook = MockFinalizeAndUploadBookUseCase();

    registerFallbackValue(FakeFile());
    registerFallbackValue(
      CircleBook(
        id: 'id',
        nostrGroudId: 'ngid',
        circleDirId: 'cdid',
        title: 'title',
        author: 'author',
        sourceFormat: BookSourceFormat.epub,
        pageCount: 1,
        chapterCount: 1,
        zbfPath: 'path',
        needsAiProcessing: false,
        zbfVersion: '1',
        createdAt: DateTime.now(),
        addedAt: DateTime.now(),
      ),
    );

    when(
      () => finalizeAndUploadBook(
        circleDirId: any(named: 'circleDirId'),
        marmotGroupId: any(named: 'marmotGroupId'),
      ),
    ).thenAnswer((_) async {});
    cubit = IngestionOrchestratorCubit(
      repository,
      createCircleBook,
      deleteBookFiles,
      finalizeAndUploadBook,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('IngestionOrchestratorCubit', () {
    test('startIngestion adds task and updates progress', () async {
      final file = FakeFile();
      final streamController = StreamController<IngestionProgress>();
      final wizardData = WizardData(title: 'My Book');

      when(
        () => repository.ingest(
          any(),
          wizardDataFuture: any(named: 'wizardDataFuture'),
          circleDirId: any(named: 'circleDirId'),
        ),
      ).thenAnswer((_) => streamController.stream);

      when(
        () => createCircleBook(
          circleDirId: any(named: 'circleDirId'),
          humanTitle: any(named: 'humanTitle'),
          metadata: any(named: 'metadata'),
        ),
      ).thenAnswer((_) async => 'marmot-group-id');

      final circleBookId = cubit.startIngestion(
        file,
        Future.value(wizardData),
        'content-hash',
      );

      expect(circleBookId, isNotEmpty);
      expect(cubit.state.tasks.containsKey(circleBookId), true);

      await Future.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.tasks[circleBookId]!.wizardData, isNotNull);
      expect(cubit.state.tasks[circleBookId]!.isGroupCreated, true);

      streamController.add(
        IngestionProgress.extracting(progress: 0.5, currentItem: 'item'),
      );

      await Future.delayed(const Duration(milliseconds: 10));
      expect(
        cubit.state.tasks[circleBookId]!.progress.stage,
        IngestionStage.extracting,
      );

      streamController.add(
        IngestionProgress.complete(
          ZbfBook(
            manifest: BookManifest(
              id: 'id',
              title: 'title',
              author: 'author',
              sourceFormat: BookSourceFormat.epub,
              pageCount: 1,
              chapterCount: 1,
              coverAsset: '',
              createdAt: DateTime.now(),
              needsAiProcessing: false,
              skippablePages: const [],
            ),
            assets: const {},
          ),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 10));
      expect(cubit.state.tasks.containsKey(circleBookId), false);

      await streamController.close();
    });

    test('cancelIngestion removes task and deletes directory', () async {
      final file = FakeFile();
      final streamController = StreamController<IngestionProgress>();

      when(
        () => repository.ingest(
          any(),
          wizardDataFuture: any(named: 'wizardDataFuture'),
          circleDirId: any(named: 'circleDirId'),
        ),
      ).thenAnswer((_) => streamController.stream);

      when(() => deleteBookFiles(any())).thenAnswer((_) async {});

      final circleBookId = cubit.startIngestion(
        file,
        Completer<WizardData>().future,
        'content-hash',
      );

      expect(cubit.state.tasks.containsKey(circleBookId), true);

      await cubit.cancelIngestion(circleBookId);

      expect(cubit.state.tasks.containsKey(circleBookId), false);
      verify(() => deleteBookFiles(circleBookId)).called(1);
    });
  });
}
