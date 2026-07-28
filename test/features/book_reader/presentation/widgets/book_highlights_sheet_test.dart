import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/features/book_reader/domain/entities/highlight.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/highlights/book_highlights_cubit.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/book_highlights_sheet.dart';

class MockBookHighlightsCubit extends Mock implements BookHighlightsCubit {}

void main() {
  late MockBookHighlightsCubit cubit;

  setUp(() {
    cubit = MockBookHighlightsCubit();
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => cubit.shareToCircle(any(), any())).thenAnswer((_) async {});
    when(() => cubit.deleteHighlight(any())).thenAnswer((_) async {});
  });

  Highlight highlightAt({
    String id = 'h1',
    int pageNumber = 3,
    String? note,
    HighlightVisibility visibility = HighlightVisibility.private,
  }) => Highlight(
    id: id,
    bookId: 'book1',
    ownerNpub: 'npub1',
    visibility: visibility,
    pageNumber: pageNumber,
    spans: const [
      HighlightSpan(originalBlockIndex: 0, startOffset: 0, endOffset: 5),
    ],
    quoteSnapshot: 'a memorable quote',
    note: note,
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  Widget buildTestWidget({required String groupId}) {
    return MaterialApp(
      theme: lightTheme,
      home: Scaffold(
        body: BlocProvider<BookHighlightsCubit>.value(
          value: cubit,
          child: BookHighlightsSheet(
            bookId: 'book1',
            groupId: groupId,
            onJumpToPage: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('renders an empty state when there are no highlights', (
    tester,
  ) async {
    when(() => cubit.state).thenReturn(const BookHighlightsLoaded([]));

    await tester.pumpWidget(buildTestWidget(groupId: ''));
    await tester.pumpAndSettle();

    expect(
      find.text('No highlights yet — select text while reading to add one.'),
      findsOneWidget,
    );
  });

  testWidgets('renders a highlight with its quote and note', (tester) async {
    when(
      () => cubit.state,
    ).thenReturn(BookHighlightsLoaded([highlightAt(note: 'my thought')]));

    await tester.pumpWidget(buildTestWidget(groupId: ''));
    await tester.pumpAndSettle();

    expect(find.text('"a memorable quote"'), findsOneWidget);
    expect(find.text('my thought'), findsOneWidget);
    expect(find.text('Page 3'), findsOneWidget);
  });

  testWidgets(
    'shows a share-to-circle icon only for private highlights on a circle book',
    (tester) async {
      when(() => cubit.state).thenReturn(BookHighlightsLoaded([highlightAt()]));

      await tester.pumpWidget(buildTestWidget(groupId: 'group1'));
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.share2), findsOneWidget);

      await tester.tap(find.byIcon(LucideIcons.share2));
      await tester.pump();

      verify(() => cubit.shareToCircle('h1', 'group1')).called(1);
    },
  );

  testWidgets('hides the share-to-circle icon for a solo (non-circle) book', (
    tester,
  ) async {
    when(() => cubit.state).thenReturn(BookHighlightsLoaded([highlightAt()]));

    await tester.pumpWidget(buildTestWidget(groupId: ''));
    await tester.pumpAndSettle();

    expect(find.byIcon(LucideIcons.share2), findsNothing);
  });

  testWidgets('tapping delete calls deleteHighlight', (tester) async {
    when(() => cubit.state).thenReturn(BookHighlightsLoaded([highlightAt()]));

    await tester.pumpWidget(buildTestWidget(groupId: ''));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(LucideIcons.trash2));
    await tester.pump();

    verify(() => cubit.deleteHighlight('h1')).called(1);
  });
}
