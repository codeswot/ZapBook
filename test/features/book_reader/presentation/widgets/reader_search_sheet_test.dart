import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/data/search/book_search_index.dart';
import 'package:zapbook/core/data/search/book_vector_index.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_search_sheet.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/core/presentation/widgets/app_input.dart';

class MockBookSearchIndex extends Mock implements BookSearchIndex {}

class MockBookVectorIndex extends Mock implements BookVectorIndex {}

void main() {
  late MockBookSearchIndex mockKeyword;
  late MockBookVectorIndex mockVectors;

  setUp(() {
    mockKeyword = MockBookSearchIndex();
    mockVectors = MockBookVectorIndex();
    getIt.reset();
    getIt.registerSingleton<BookSearchIndex>(mockKeyword);
    getIt.registerSingleton<BookVectorIndex>(mockVectors);
  });

  tearDown(() {
    getIt.reset();
  });

  testWidgets('ReaderSearchSheet renders and performs search', (
    WidgetTester tester,
  ) async {
    when(
      () => mockKeyword.search(
        any(),
        circleDirId: any(named: 'circleDirId'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => [
        BookSearchHit(
          circleDirId: 'test_book',
          pageNumber: 1,
          chapterTitle: 'Chapter 1',
          snippet:
              'Hello ${BookSearchIndex.highlightStart}world${BookSearchIndex.highlightEnd}',
        ),
      ],
    );

    when(
      () => mockVectors.search(
        any(),
        circleDirId: any(named: 'circleDirId'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => []);

    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: Scaffold(
          body: ReaderSearchSheet(
            circleDirId: 'test_book',
            onSelect: (page, query) {},
          ),
        ),
      ),
    );

    expect(find.byType(ReaderSearchSheet), findsOneWidget);

    // Enter text to trigger search
    await tester.enterText(find.byType(AppInput), 'world');

    // Wait for debounce (250ms)
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Verify results
    expect(find.text('Page 1'), findsOneWidget);
    expect(find.textContaining('world'), findsWidgets);
  });
}
