import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/features/cheers/presentation/widgets/cheers_view.dart';
import 'package:zapbook/features/cheers/presentation/bloc/cheers_cubit.dart';
import 'package:zapbook/features/cheers/presentation/bloc/cheers_state.dart';
import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/features/cheers/presentation/widgets/cheers_activity_card.dart';

class MockCheersCubit extends Mock implements CheersCubit {}

void main() {
  late MockCheersCubit cheersCubit;

  setUp(() {
    cheersCubit = MockCheersCubit();
    when(() => cheersCubit.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget buildTestWidget() {
    return BlocProvider<CheersCubit>.value(
      value: cheersCubit,
      child: MaterialApp(
        theme: lightTheme,
        home: const Scaffold(body: CheersView()),
      ),
    );
  }

  group('CheersView', () {
    testWidgets('renders loading state', (tester) async {
      when(() => cheersCubit.state).thenReturn(const CheersLoading());

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('All'), findsOneWidget); // Filter chip
      expect(
        find.byType(CircularProgressIndicator),
        findsNothing,
      ); // Using shimmer probably
    });

    testWidgets('renders loaded state with activities', (tester) async {
      final activity = CheersActivity(
        id: '1',
        actorNpub: 'npub1',
        actorName: 'Alice',
        actorAvatar: 'avatar.png',
        bookTitle: 'Test Book',
        circleBookId: 'cb1',
        activityDescription: 'Zapped you',
        timestamp: DateTime.now(),
        type: 'zap',
        isUnread: false,
        zapAmount: 100,
      );

      when(
        () => cheersCubit.state,
      ).thenReturn(CheersLoaded(activities: [activity], activeFilter: 'All'));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(CheersActivityCard), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('renders empty state', (tester) async {
      when(
        () => cheersCubit.state,
      ).thenReturn(const CheersLoaded(activities: [], activeFilter: 'All'));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No cheers found'), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      when(() => cheersCubit.state).thenReturn(const CheersError('Test Error'));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Test Error'), findsOneWidget);
    });

    testWidgets('calls loadMore when scrolling to bottom', (tester) async {
      final activities = List.generate(
        10,
        (i) => CheersActivity(
          id: 'id$i',
          actorNpub: 'npub$i',
          actorName: 'User $i',
          actorAvatar: 'avatar.png',
          bookTitle: 'Test Book',
          circleBookId: 'cb1',
          activityDescription: 'Action',
          timestamp: DateTime.now().subtract(Duration(days: i)),
          type: 'zap',
          isUnread: false,
        ),
      );

      when(
        () => cheersCubit.state,
      ).thenReturn(CheersLoaded(activities: activities, activeFilter: 'All'));

      when(() => cheersCubit.loadMore()).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView).last, const Offset(0, -1000));
      await tester.pumpAndSettle();

      verify(() => cheersCubit.loadMore()).called(greaterThanOrEqualTo(1));
    });
  });
}
