import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/features/book_reader/domain/entities/highlight.dart';
import 'package:zapbook/features/book_reader/domain/usecases/highlight_usecases.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/highlights/highlights_cubit.dart';

class MockSaveHighlightUseCase extends Mock implements SaveHighlightUseCase {}

class MockAddNoteUseCase extends Mock implements AddNoteUseCase {}

class MockShareHighlightToCircleUseCase extends Mock
    implements ShareHighlightToCircleUseCase {}

class MockDeleteHighlightUseCase extends Mock
    implements DeleteHighlightUseCase {}

class MockWatchHighlightsForPageUseCase extends Mock
    implements WatchHighlightsForPageUseCase {}

void main() {
  late MockSaveHighlightUseCase save;
  late MockAddNoteUseCase addNote;
  late MockShareHighlightToCircleUseCase share;
  late MockDeleteHighlightUseCase delete;
  late MockWatchHighlightsForPageUseCase watchPage;
  late StreamController<List<Highlight>> pageController;

  setUp(() {
    save = MockSaveHighlightUseCase();
    addNote = MockAddNoteUseCase();
    share = MockShareHighlightToCircleUseCase();
    delete = MockDeleteHighlightUseCase();
    watchPage = MockWatchHighlightsForPageUseCase();
    pageController = StreamController<List<Highlight>>.broadcast();

    when(
      () => watchPage(
        bookId: any(named: 'bookId'),
        pageNumber: any(named: 'pageNumber'),
      ),
    ).thenAnswer((_) => pageController.stream);
  });

  tearDown(() {
    pageController.close();
  });

  HighlightsCubit buildCubit() =>
      HighlightsCubit(save, addNote, share, delete, watchPage);

  final testHighlight = Highlight(
    id: 'h1',
    bookId: 'book1',
    ownerNpub: 'npub1',
    visibility: HighlightVisibility.private,
    pageNumber: 3,
    spans: const [
      HighlightSpan(originalBlockIndex: 0, startOffset: 0, endOffset: 5),
    ],
    quoteSnapshot: 'quote',
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  group('HighlightsCubit', () {
    test('initial state is HighlightsLoading', () {
      expect(buildCubit().state, isA<HighlightsLoading>());
    });

    blocTest<HighlightsCubit, HighlightsState>(
      'openPage subscribes and emits highlights for the page',
      build: buildCubit,
      act: (cubit) async {
        cubit.openPage(bookId: 'book1', pageNumber: 3);
        pageController.add([testHighlight]);
      },
      expect: () => [isA<HighlightsLoading>(), isA<HighlightsLoaded>()],
      verify: (_) {
        verify(() => watchPage(bookId: 'book1', pageNumber: 3)).called(1);
      },
    );

    blocTest<HighlightsCubit, HighlightsState>(
      'openPage is a no-op when called with the same page twice',
      build: buildCubit,
      act: (cubit) {
        cubit.openPage(bookId: 'book1', pageNumber: 3);
        cubit.openPage(bookId: 'book1', pageNumber: 3);
      },
      expect: () => [isA<HighlightsLoading>()],
      verify: (_) {
        verify(() => watchPage(bookId: 'book1', pageNumber: 3)).called(1);
      },
    );

    test(
      'highlight forwards to SaveHighlightUseCase with current page',
      () async {
        when(
          () => save(
            bookId: any(named: 'bookId'),
            pageNumber: any(named: 'pageNumber'),
            spans: any(named: 'spans'),
            quoteSnapshot: any(named: 'quoteSnapshot'),
          ),
        ).thenAnswer((_) async => testHighlight);

        final cubit = buildCubit();
        cubit.openPage(bookId: 'book1', pageNumber: 3);

        final result = await cubit.highlight(
          spans: testHighlight.spans,
          quoteSnapshot: 'quote',
        );

        expect(result, testHighlight);
        verify(
          () => save(
            bookId: 'book1',
            pageNumber: 3,
            spans: testHighlight.spans,
            quoteSnapshot: 'quote',
          ),
        ).called(1);
      },
    );

    test('addNote forwards to AddNoteUseCase', () async {
      when(
        () => addNote(
          highlightId: any(named: 'highlightId'),
          note: any(named: 'note'),
        ),
      ).thenAnswer((_) async {});

      await buildCubit().addNote('h1', 'a note');

      verify(() => addNote(highlightId: 'h1', note: 'a note')).called(1);
    });

    test('shareToCircle forwards to ShareHighlightToCircleUseCase', () async {
      when(
        () => share(
          highlightId: any(named: 'highlightId'),
          groupId: any(named: 'groupId'),
        ),
      ).thenAnswer((_) async {});

      await buildCubit().shareToCircle('h1', 'group1');

      verify(() => share(highlightId: 'h1', groupId: 'group1')).called(1);
    });

    test('deleteHighlight forwards to DeleteHighlightUseCase', () async {
      when(() => delete(any())).thenAnswer((_) async {});

      await buildCubit().deleteHighlight('h1');

      verify(() => delete('h1')).called(1);
    });
  });
}
