import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_body.dart';
import 'package:zapbook/core/presentation/bloc/performance/performance_cubit.dart';
import 'package:zapbook/core/domain/entities/perf_mode.dart';
import 'package:zapbook/core/presentation/bloc/performance/performance_state.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/core/presentation/theme/reading_style.dart';
import 'package:zapbook/zbf/zbf.dart';

class MockPerformanceCubit extends Mock implements PerformanceCubit {}

void main() {
  late MockPerformanceCubit performanceCubit;

  setUp(() {
    performanceCubit = MockPerformanceCubit();
    when(() => performanceCubit.state).thenReturn(
      const PerformanceState(reduceEffects: true, mode: PerfMode.auto),
    );
    when(() => performanceCubit.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget buildTestWidget({
    List<BookBlock> blocks = const [],
    String? highlightQuery,
    double? initialScrollOffset,
    bool canGoForward = true,
    bool canGoBack = true,
  }) {
    return BlocProvider<PerformanceCubit>.value(
      value: performanceCubit,
      child: MaterialApp(
        theme: lightTheme,
        home: Builder(
          builder: (context) {
            final style = ReadingStyle.of(
              ReaderFont.sans,
              context.colors,
              textScale: 1.0,
            );
            return Scaffold(
              body: ReaderBody(
                blocks: blocks,
                style: style,
                scrollDirection: ReaderScrollDirection.vertical,
                asset: (ref) async => null,
                canGoForward: canGoForward,
                canGoBack: canGoBack,
                onTurnForward: () {},
                onTurnBackward: () {},
                onTap: () {},
                onUserScrollDirection: (dir) {},
                onPullChanged: (pull) {},
                onScrollOffsetChanged: (offset) {},
                initialScrollOffset: initialScrollOffset,
                highlightQuery: highlightQuery,
                onHighlightComplete: () {},
              ),
            );
          },
        ),
      ),
    );
  }

  group('ReaderBody', () {
    testWidgets('renders blocks', (tester) async {
      final List<BookBlock> blocks = [
        const HeadingBlock(text: 'Chapter 1', level: 1),
        const ParagraphBlock(text: 'This is a test paragraph.'),
      ];

      await tester.pumpWidget(buildTestWidget(blocks: blocks));
      await tester.pumpAndSettle();

      expect(find.text('Chapter 1'), findsOneWidget);
      expect(find.text('This is a test paragraph.'), findsOneWidget);
    });

    testWidgets('applies initial scroll offset', (tester) async {
      final List<BookBlock> blocks = List.generate(
        100,
        (i) => ParagraphBlock(text: 'Paragraph $i'),
      );

      await tester.pumpWidget(
        buildTestWidget(blocks: blocks, initialScrollOffset: 500),
      );
      await tester.pumpAndSettle();

      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      expect(scrollable.position.pixels, greaterThan(0));
    });

    testWidgets('handles tap events', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        BlocProvider<PerformanceCubit>.value(
          value: performanceCubit,
          child: MaterialApp(
            theme: lightTheme,
            home: Builder(
              builder: (context) {
                final style = ReadingStyle.of(ReaderFont.sans, context.colors);
                return Scaffold(
                  body: ReaderBody(
                    blocks: const <BookBlock>[ParagraphBlock(text: 'Test')],
                    style: style,
                    scrollDirection: ReaderScrollDirection.vertical,
                    asset: (ref) async => null,
                    canGoForward: true,
                    canGoBack: true,
                    onTurnForward: () {},
                    onTurnBackward: () {},
                    onTap: () => tapped = true,
                    onUserScrollDirection: (dir) {},
                    onPullChanged: (pull) {},
                    onScrollOffsetChanged: (offset) {},
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tapped, isTrue);
    });

    testWidgets('pull indicator updates', (tester) async {
      ReaderPullState? lastPull;

      await tester.pumpWidget(
        BlocProvider<PerformanceCubit>.value(
          value: performanceCubit,
          child: MaterialApp(
            theme: lightTheme,
            home: Builder(
              builder: (context) {
                final style = ReadingStyle.of(ReaderFont.sans, context.colors);
                return Scaffold(
                  body: ReaderBody(
                    blocks: const <BookBlock>[ParagraphBlock(text: 'Test')],
                    style: style,
                    scrollDirection: ReaderScrollDirection.vertical,
                    asset: (ref) async => null,
                    canGoForward: true,
                    canGoBack: true,
                    onTurnForward: () {},
                    onTurnBackward: () {},
                    onTap: () {},
                    onUserScrollDirection: (dir) {},
                    onPullChanged: (pull) => lastPull = pull,
                    onScrollOffsetChanged: (offset) {},
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.drag(find.byType(ListView), const Offset(0, 150));
      await tester.pump();

      expect(lastPull, isNotNull);
      expect(lastPull!.edge, ReaderPullEdge.top);
      expect(lastPull!.armed, isTrue);
    });

    testWidgets(
      'horizontal pull indicator updates when scrollDirection is horizontal',
      (tester) async {
        ReaderPullState? lastPull;

        await tester.pumpWidget(
          BlocProvider<PerformanceCubit>.value(
            value: performanceCubit,
            child: MaterialApp(
              theme: lightTheme,
              home: Builder(
                builder: (context) {
                  final style = ReadingStyle.of(
                    ReaderFont.sans,
                    context.colors,
                  );
                  return Scaffold(
                    body: ReaderBody(
                      blocks: const <BookBlock>[ParagraphBlock(text: 'Test')],
                      style: style,
                      scrollDirection: ReaderScrollDirection.horizontal,
                      asset: (ref) async => null,
                      canGoForward: true,
                      canGoBack: true,
                      onTurnForward: () {},
                      onTurnBackward: () {},
                      onTap: () {},
                      onUserScrollDirection: (dir) {},
                      onPullChanged: (pull) => lastPull = pull,
                      onScrollOffsetChanged: (offset) {},
                    ),
                  );
                },
              ),
            ),
          ),
        );

        final listViewRect = tester.getRect(find.byType(ListView));
        final startPos =
            listViewRect.centerLeft +
            const Offset(10, 0); // start near left edge
        final gesture = await tester.startGesture(startPos);
        await gesture.moveBy(const Offset(-30, 0)); // break slop
        await tester.pump();
        await gesture.moveBy(
          const Offset(-200, 0),
        ); // generate large overscroll
        await tester.pump();

        expect(lastPull, isNotNull);
        expect(lastPull!.edge, ReaderPullEdge.right);
        expect(lastPull!.armed, isTrue);

        await gesture.up();
        await tester.pump();
      },
    );
  });
}
