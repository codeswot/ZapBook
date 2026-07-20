import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reading_progress/reading_progress.dart';

import 'package:zapbook/core/domain/usecases/watch_my_reading_progress.dart';
import 'package:zapbook/features/home/domain/usecases/touch_dashboard_book_opened.dart';
import 'package:zapbook/core/data/infrastructure/reading_stats_service.dart';
import 'package:zapbook/features/book_reader/domain/usecases/book_reader_usecases.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/reading_progress_cubit.dart';
import 'package:zapbook/zbf/zbf.dart';

class MockSaveReadingSnapshotUseCase extends Mock
    implements SaveReadingSnapshotUseCase {}

class MockLoadReadingSnapshotUseCase extends Mock
    implements LoadReadingSnapshotUseCase {}

class MockReportReadingProgressUseCase extends Mock
    implements ReportReadingProgressUseCase {}

class MockWatchMyReadingProgressUseCase extends Mock
    implements WatchMyReadingProgressUseCase {}

class MockTouchDashboardBookOpened extends Mock
    implements TouchDashboardBookOpened {}

class MockReadingStatsService extends Mock implements ReadingStatsService {}

class FakeReadingState extends Fake implements ReadingState {}

ZbfBookHandle _handle() {
  final manifest = BookManifest(
    id: 'test_book',
    title: 'Test',
    author: 'Author',
    sourceFormat: BookSourceFormat.pdf,
    pageCount: 3,
    chapterCount: 3,
    coverAsset: 'cover.png',
    createdAt: DateTime.now(),
    needsAiProcessing: false,
    pageWords: const [100, 150, 120],
  );
  return ZbfBookHandle(dirPath: '', manifest: manifest);
}

void main() {
  late MockSaveReadingSnapshotUseCase mockSaveSnapshot;
  late MockLoadReadingSnapshotUseCase mockLoadSnapshot;
  late MockReportReadingProgressUseCase mockReportProgress;

  late MockWatchMyReadingProgressUseCase mockWatchProgress;
  late MockTouchDashboardBookOpened mockTouchOpened;

  setUpAll(() {
    registerFallbackValue(FakeReadingState());
  });

  setUp(() {
    mockSaveSnapshot = MockSaveReadingSnapshotUseCase();
    mockLoadSnapshot = MockLoadReadingSnapshotUseCase();
    mockReportProgress = MockReportReadingProgressUseCase();
    mockWatchProgress = MockWatchMyReadingProgressUseCase();
    mockTouchOpened = MockTouchDashboardBookOpened();

    when(() => mockTouchOpened(any())).thenAnswer((_) async {});

    when(
      () => mockSaveSnapshot(
        any(),
        any(),
        scrollOffset: any(named: 'scrollOffset'),
      ),
    ).thenAnswer((_) async {});
  });

  ReadingProgressCubit buildCubit() {
    final cubit =
        ReadingProgressCubit(
          mockSaveSnapshot,
          mockLoadSnapshot,
          mockReportProgress,
          mockWatchProgress,
          mockTouchOpened,
        )..open(
          _handle(),
          circleDirId: 'test_book',
          groupId: 'test_group',
          clock: () => 100000,
        );
    addTearDown(cubit.close);
    return cubit;
  }

  group('ReadingProgressCubit', () {
    test('opens to empty progress', () {
      final cubit = buildCubit();
      expect(cubit.state, const ReadingProgressState());
      expect(cubit.state.wordsRead, 0);
      expect(cubit.totalWords, 370);
      expect(cubit.wordProgress, 0.0);
    });

    test('start opens the initial page', () {
      final cubit = buildCubit();
      cubit.start(initialPage: 0);
      expect(cubit.state.currentPage, 0);
    });

    test('openPage projects the current page', () {
      final cubit = buildCubit();
      cubit.openPage(1);
      expect(cubit.state.currentPage, 1);
    });

    test('restore seeds engine and projects words read', () async {
      when(() => mockLoadSnapshot('test_book')).thenAnswer(
        (_) async => (
          state: const ReadingState(
            wpm: 250,
            completedPages: {},
            visitedPages: {0},
            partials: {},
            wordsRead: 50,
            pointsBanked: 10,
            milestonesReached: 1,
            currentPage: 0,
            sessionEngagedMs: 0,
            bookCompleted: false,
            open: null,
          ),
          scrollOffset: 123.4,
        ),
      );

      final cubit = buildCubit();
      final result = await cubit.restore();

      expect(result.page, 0);
      expect(result.scrollOffset, 123.4);
      expect(cubit.state.wordsRead, 50);
      expect(cubit.state.fraction, closeTo(50 / 370, 0.0001));
    });

    test('tick while paused does not advance state', () {
      final cubit = buildCubit();
      cubit.start(initialPage: 0);
      cubit.pause();
      final afterPause = cubit.state;
      cubit.tick();
      expect(cubit.state, afterPause);
    });

    test('pause saves a dirty session', () {
      final cubit = buildCubit();
      cubit.openPage(1);
      cubit.pause();
      verify(
        () => mockSaveSnapshot(
          any(),
          any(),
          scrollOffset: any(named: 'scrollOffset'),
        ),
      ).called(1);
    });

    test('closeSession flushes and saves', () {
      final cubit = buildCubit();
      cubit.openPage(0);
      cubit.closeSession();
      verify(
        () => mockSaveSnapshot(
          any(),
          any(),
          scrollOffset: any(named: 'scrollOffset'),
        ),
      ).called(1);
    });

    test('saveScrollOffset persists the offset on save', () {
      final cubit = buildCubit();
      cubit.saveScrollOffset(50.0);
      cubit.pause();
      verify(
        () => mockSaveSnapshot(any(), any(), scrollOffset: 50.0),
      ).called(1);
    });

    Future<ReadingProgressCubit> buildCubitWithWordsRead(int wordsRead) async {
      when(() => mockLoadSnapshot('test_book')).thenAnswer(
        (_) async => (
          state: ReadingState(
            wpm: 250,
            completedPages: const {0, 1},
            visitedPages: const {0, 1, 2},
            partials: const {},
            wordsRead: wordsRead,
            pointsBanked: 2,
            milestonesReached: 2,
            currentPage: 2,
            sessionEngagedMs: 0,
            bookCompleted: false,
            open: null,
          ),
          scrollOffset: null,
        ),
      );
      final cubit = buildCubit();
      await cubit.restore();
      cubit.start(initialPage: 2);
      return cubit;
    }

    test('markComplete finishes the book and saves', () async {
      final cubit = await buildCubitWithWordsRead(340);

      cubit.markComplete();

      expect(cubit.state.bookCompleted, true);
      expect(cubit.state.wordsRead, cubit.totalWords);
      expect(cubit.state.fraction, 1.0);
      verify(
        () => mockSaveSnapshot(
          any(),
          any(),
          scrollOffset: any(named: 'scrollOffset'),
        ),
      ).called(greaterThanOrEqualTo(1));
      verify(
        () => mockReportProgress.report(
          circleDirId: any(named: 'circleDirId'),
          groupId: any(named: 'groupId'),
          currentPage: any(named: 'currentPage'),
          currentWordCount: cubit.totalWords,
          totalWords: cubit.totalWords,
          fraction: 1.0,
          milestonesReached: 2,
          bookCompleted: true,
        ),
      ).called(greaterThanOrEqualTo(1));
    });

    test('markComplete is a no-op once already completed', () async {
      final cubit = await buildCubitWithWordsRead(340);
      cubit.markComplete();
      expect(cubit.state.bookCompleted, true);
      final completedState = cubit.state;

      cubit.markComplete();

      expect(cubit.state, completedState);
    });

    test('markComplete is a no-op below the 90 percent threshold', () async {
      final cubit = await buildCubitWithWordsRead(300);

      cubit.markComplete();

      expect(cubit.state.bookCompleted, false);
      expect(cubit.state.wordsRead, 300);
      verifyNever(
        () => mockReportProgress.report(
          circleDirId: any(named: 'circleDirId'),
          groupId: any(named: 'groupId'),
          currentPage: any(named: 'currentPage'),
          currentWordCount: any(named: 'currentWordCount'),
          totalWords: any(named: 'totalWords'),
          fraction: any(named: 'fraction'),
          milestonesReached: any(named: 'milestonesReached'),
          bookCompleted: true,
        ),
      );
    });
  });
}
