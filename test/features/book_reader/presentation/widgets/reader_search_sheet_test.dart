import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/domain/entities/book_search_hit.dart';
import 'package:zapbook/core/domain/usecases/book_search_usecases.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/reader_search_cubit.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_search_sheet.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/core/presentation/widgets/app_input.dart';

class MockSearchBooks extends Mock implements SearchBooks {}

void main() {
  late MockSearchBooks mockSearch;

  setUp(() {
    mockSearch = MockSearchBooks();
  });

  Widget host() => MaterialApp(
    theme: lightTheme,
    home: Scaffold(
      body: BlocProvider<ReaderSearchCubit>(
        create: (_) => ReaderSearchCubit(mockSearch),
        child: ReaderSearchSheet(
          circleDirId: 'test_book',
          onSelect: (page, query) {},
        ),
      ),
    ),
  );

  testWidgets('ReaderSearchSheet renders and performs search', (
    WidgetTester tester,
  ) async {
    when(
      () => mockSearch.call(
        any(),
        circleDirId: any(named: 'circleDirId'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => const BlendedSearchResult(
        semanticAvailable: true,
        hits: [
          BookSearchHit(
            circleDirId: 'test_book',
            pageNumber: 1,
            chapterTitle: 'Chapter 1',
            snippet:
                'Hello ${BookSearchHit.highlightStart}world${BookSearchHit.highlightEnd}',
          ),
        ],
      ),
    );

    await tester.pumpWidget(host());

    expect(find.byType(ReaderSearchSheet), findsOneWidget);

    await tester.enterText(find.byType(AppInput), 'world');

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Page 1'), findsOneWidget);
    expect(find.textContaining('world'), findsWidgets);
    verify(
      () => mockSearch.call('world', circleDirId: 'test_book', limit: 30),
    ).called(1);
  });

  testWidgets('shows AI-unavailable note when semantic search fails', (
    WidgetTester tester,
  ) async {
    when(
      () => mockSearch.call(
        any(),
        circleDirId: any(named: 'circleDirId'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async =>
          const BlendedSearchResult(semanticAvailable: false, hits: []),
    );

    await tester.pumpWidget(host());

    await tester.enterText(find.byType(AppInput), 'world');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.textContaining('AI search unavailable'), findsOneWidget);
  });
}
