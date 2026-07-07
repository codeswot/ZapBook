import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/services/quiz_service.dart';
import 'package:zapbook/features/book_reader/data/reading_progress_repository.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/reading_progress_cubit.dart';
import 'package:reading_progress/reading_progress.dart';

class MockReadingProgressRepository extends Mock
    implements ReadingProgressRepository {}

class MockQuizService extends Mock implements QuizService {}

class FakeReadingState extends Fake implements ReadingState {}

void main() {
  late MockReadingProgressRepository mockRepo;
  late MockQuizService mockQuizService;
  late ReadingDeps testDeps;

  setUpAll(() {
    registerFallbackValue(FakeReadingState());
  });

  setUp(() {
    mockQuizService = MockQuizService();
    mockRepo = MockReadingProgressRepository();

    testDeps = ReadingDeps(
      density: const BookDensity(pageWords: [100, 150, 120]),
      config: const ProgressConfig(),
    );
    when(
      () => mockQuizService.onCompleted,
    ).thenAnswer((_) => const Stream.empty());
  });

  int fakeClock() => 100000;

  ReadingProgressCubit buildCubit() {
    return ReadingProgressCubit.forDeps(
      deps: testDeps,
      circleBookId: 'test_book',
      clock: fakeClock,
      repository: mockRepo,
    );
  }

  group('ReadingProgressCubit', () {
    test('initial state', () {
      final cubit = buildCubit();
      expect(cubit.state.wordsRead, 0);
      expect(cubit.totalWords, 370);
      expect(cubit.wordProgress, 0.0);
    });

    test('start opens page and begins timer', () {
      final cubit = buildCubit();
      cubit.start(initialPage: 0);
      expect(cubit.state.currentPage, 0);
    });

    test('restore loads snapshot if available', () async {
      when(() => mockRepo.loadSnapshot('test_book')).thenAnswer(
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
      expect(cubit.state.wpm, 250);
      expect(cubit.state.pointsBanked, 10);
    });

    test('openPage updates current page', () {
      final cubit = buildCubit();
      cubit.openPage(1);
      expect(cubit.state.currentPage, 1);
    });

    test('pause and resume', () {
      when(
        () => mockRepo.saveSnapshot(
          any(),
          any(),
          scrollOffset: any(named: 'scrollOffset'),
        ),
      ).thenAnswer((_) async {});

      final cubit = buildCubit();
      cubit.openPage(1); // dirty the state
      cubit.pause();
      // Should have called save
      verify(
        () => mockRepo.saveSnapshot(
          any(),
          any(),
          scrollOffset: any(named: 'scrollOffset'),
        ),
      ).called(1);

      cubit.resume();
      cubit.tick(); // shouldn't crash
    });

    test('closeSession flushes and saves', () {
      when(
        () => mockRepo.saveSnapshot(
          any(),
          any(),
          scrollOffset: any(named: 'scrollOffset'),
        ),
      ).thenAnswer((_) async {});

      final cubit = buildCubit();
      cubit.openPage(0);
      cubit.closeSession();

      verify(
        () => mockRepo.saveSnapshot(
          any(),
          any(),
          scrollOffset: any(named: 'scrollOffset'),
        ),
      ).called(1);
    });

    test('saveScrollOffset sets offset and dirties state', () {
      when(
        () => mockRepo.saveSnapshot(
          any(),
          any(),
          scrollOffset: any(named: 'scrollOffset'),
        ),
      ).thenAnswer((_) async {});

      final cubit = buildCubit();
      cubit.saveScrollOffset(50.0);
      cubit.pause(); // force save
      verify(
        () => mockRepo.saveSnapshot(any(), any(), scrollOffset: 50.0),
      ).called(1);
    });
  });
}
