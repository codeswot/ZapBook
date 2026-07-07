import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_block_view.dart';
import 'package:zapbook/core/presentation/bloc/performance/performance_cubit.dart';
import 'package:zapbook/core/presentation/bloc/performance/performance_state.dart';
import 'package:zapbook/core/services/performance_service.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/theme/reading_style.dart';
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
    required BookBlock block,
    String? highlightQuery,
    double? highlightProgress,
    Future<Uint8List?> Function(String)? asset,
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
              body: ReaderBlockView(
                block: block,
                style: style,
                asset: asset ?? (ref) async => null,
                highlightQuery: highlightQuery,
                highlightProgress: highlightProgress,
              ),
            );
          },
        ),
      ),
    );
  }

  group('ReaderBlockView', () {
    testWidgets('renders HeadingBlock', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(block: const HeadingBlock(text: 'Chapter 1', level: 1)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chapter 1'), findsOneWidget);
    });

    testWidgets('renders ParagraphBlock', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(block: const ParagraphBlock(text: 'Paragraph text.')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Paragraph text.'), findsOneWidget);
    });

    testWidgets('renders PullquoteBlock', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(block: const PullquoteBlock(text: 'Pullquote text.')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pullquote text.'), findsOneWidget);
    });

    testWidgets('renders CodeBlock', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(block: const CodeBlock(text: 'Code text.')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Code text.'), findsOneWidget);
    });

    testWidgets('renders CaptionBlock', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(block: const CaptionBlock(text: 'Caption text.')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Caption text.'), findsOneWidget);
    });

    testWidgets('renders ImageBlock', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          block: const ImageBlock(assetRef: 'img1', altText: 'Alt text'),
          asset: (ref) async => Uint8List.fromList([1, 2, 3]),
        ),
      );
      await tester.pump();
      expect(find.text('[missing image: img1]'), findsNothing);
      expect(find.text('Alt text'), findsOneWidget);
    });

    testWidgets('renders ImageBlock with missing image', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          block: const ImageBlock(assetRef: 'img2', altText: 'Alt text'),
          asset: (ref) async => null,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('[missing image: img2]'), findsOneWidget);
      expect(find.text('Alt text'), findsOneWidget);
    });

    testWidgets('renders DividerBlock', (tester) async {
      await tester.pumpWidget(buildTestWidget(block: const DividerBlock()));
      await tester.pumpAndSettle();
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('renders PageBreakBlock', (tester) async {
      await tester.pumpWidget(buildTestWidget(block: const PageBreakBlock()));
      await tester.pumpAndSettle();
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('highlights text when query matches', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          block: const ParagraphBlock(text: 'This is a highlight test.'),
          highlightQuery: 'highlight',
          highlightProgress: 1.0,
        ),
      );
      await tester.pumpAndSettle();

      final richTextFinder = find.byType(RichText);
      expect(richTextFinder, findsOneWidget);
      final richText = tester.widget<RichText>(richTextFinder);
      expect(richText.text.toPlainText(), 'This is a highlight test.');
    });

    testWidgets('renders text runs with styling', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          block: const ParagraphBlock(
            text: 'Bold and italic',
            runs: [
              TextRun('Bold', bold: true, italic: false, code: false),
              TextRun(' and ', bold: false, italic: false, code: false),
              TextRun('italic', bold: false, italic: true, code: false),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RichText), findsOneWidget);
    });
  });
}
