import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/features/book_reader/domain/entities/highlight.dart';
import 'package:zapbook/features/book_reader/domain/usecases/highlight_usecases.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/highlights/book_highlights_cubit.dart';

class MockWatchHighlightsForBookUseCase extends Mock
    implements WatchHighlightsForBookUseCase {}

class MockShareHighlightToCircleUseCase extends Mock
    implements ShareHighlightToCircleUseCase {}

class MockDeleteHighlightUseCase extends Mock
    implements DeleteHighlightUseCase {}

void main() {
  late MockWatchHighlightsForBookUseCase watchBook;
  late MockShareHighlightToCircleUseCase share;
  late MockDeleteHighlightUseCase delete;
  late StreamController<List<Highlight>> bookController;

  setUp(() {
    watchBook = MockWatchHighlightsForBookUseCase();
    share = MockShareHighlightToCircleUseCase();
    delete = MockDeleteHighlightUseCase();
    bookController = StreamController<List<Highlight>>.broadcast();

    when(() => watchBook(any())).thenAnswer((_) => bookController.stream);
  });

  tearDown(() {
    bookController.close();
  });

  BookHighlightsCubit buildCubit() =>
      BookHighlightsCubit(watchBook, share, delete);

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

  group('BookHighlightsCubit', () {
    test('initial state is BookHighlightsLoading', () {
      expect(buildCubit().state, isA<BookHighlightsLoading>());
    });

    blocTest<BookHighlightsCubit, BookHighlightsState>(
      'load subscribes and emits all highlights for the book',
      build: buildCubit,
      act: (cubit) async {
        cubit.load('book1');
        bookController.add([testHighlight]);
      },
      expect: () => [isA<BookHighlightsLoading>(), isA<BookHighlightsLoaded>()],
      verify: (_) {
        verify(() => watchBook('book1')).called(1);
      },
    );

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
