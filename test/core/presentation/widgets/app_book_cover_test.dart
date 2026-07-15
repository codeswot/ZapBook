import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zapbook/core/presentation/widgets/app_book_cover.dart';
import 'package:zapbook/core/presentation/widgets/pulsing_blurhash.dart';
import 'package:zapbook/core/presentation/bloc/performance/performance_cubit.dart';
import 'package:zapbook/core/presentation/bloc/performance/performance_state.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';

import 'package:zapbook/core/domain/entities/perf_mode.dart';

class MockPerformanceCubit extends Mock implements PerformanceCubit {}

void main() {
  late MockPerformanceCubit mockPerformanceCubit;

  setUp(() {
    mockPerformanceCubit = MockPerformanceCubit();
    when(() => mockPerformanceCubit.state).thenReturn(
      const PerformanceState(reduceEffects: false, mode: PerfMode.auto),
    );
    when(
      () => mockPerformanceCubit.stream,
    ).thenAnswer((_) => const Stream.empty());
  });

  Widget buildTestApp(Widget child) {
    return MaterialApp(
      theme: lightTheme,
      home: Scaffold(
        body: BlocProvider<PerformanceCubit>.value(
          value: mockPerformanceCubit,
          child: child,
        ),
      ),
    );
  }

  group('AppBookCover', () {
    testWidgets('renders basic cover with title', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const AppBookCover(title: 'Test Book', showInfos: true)),
      );

      expect(find.text('Test Book'), findsOneWidget);
    });

    testWidgets('renders cover with author', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppBookCover(
            title: 'Test Book',
            author: 'John Doe',
            showInfos: true,
          ),
        ),
      );

      expect(find.text('Test Book'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('renders blurhash when provided', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppBookCover(blurhash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj'),
        ),
      );

      expect(find.byType(PulsingBlurHash), findsOneWidget);
    });

    testWidgets('renders different hues', (tester) async {
      for (final hue in AppBookCoverHue.values) {
        await tester.pumpWidget(
          buildTestApp(
            AppBookCover(title: 'Hue $hue', hue: hue, showInfos: true),
          ),
        );
        expect(find.text('Hue $hue'), findsOneWidget);
      }
    });

    testWidgets('respects reduceEffects setting', (tester) async {
      when(() => mockPerformanceCubit.state).thenReturn(
        const PerformanceState(reduceEffects: true, mode: PerfMode.auto),
      );

      await tester.pumpWidget(
        buildTestApp(const AppBookCover(title: 'Test Book', showInfos: true)),
      );

      expect(find.text('Test Book'), findsOneWidget);
      expect(find.byType(ShaderMask), findsNothing);
    });
  });
}
