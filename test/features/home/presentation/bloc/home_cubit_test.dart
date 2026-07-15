import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/features/home/domain/entities/home_dashboard.dart';
import 'package:zapbook/features/home/domain/usecases/touch_dashboard_book_opened.dart';
import 'package:zapbook/features/home/domain/usecases/watch_home_dashboard.dart';
import 'package:zapbook/features/home/presentation/bloc/home_cubit.dart';
import 'package:zapbook/features/home/presentation/bloc/home_state.dart';

class MockWatchHomeDashboard extends Mock implements WatchHomeDashboard {}

class MockTouchDashboardBookOpened extends Mock
    implements TouchDashboardBookOpened {}

void main() {
  late MockWatchHomeDashboard watchHomeDashboard;
  late MockTouchDashboardBookOpened touchDashboardBookOpened;
  late StreamController<HomeDashboard> dashboardController;

  setUp(() {
    watchHomeDashboard = MockWatchHomeDashboard();
    touchDashboardBookOpened = MockTouchDashboardBookOpened();
    dashboardController = StreamController<HomeDashboard>.broadcast();

    when(
      () => watchHomeDashboard.call(),
    ).thenAnswer((_) => dashboardController.stream);
  });

  tearDown(() {
    dashboardController.close();
  });

  HomeCubit buildCubit() =>
      HomeCubit(watchHomeDashboard, touchDashboardBookOpened);

  group('HomeCubit', () {
    test('initial state is HomeLoading', () {
      final cubit = buildCubit();
      expect(cubit.state, const HomeLoading());
    });

    blocTest<HomeCubit, HomeState>(
      'emits HomeLoaded when stream emits dashboard',
      build: buildCubit,
      act: (cubit) {
        dashboardController.add(
          const HomeDashboard(
            stats: HomeDashboardStats(
              dayStreak: 0,
              satsEarned: 0,
              booksRead: 0,
            ),
            circles: [],
          ),
        );
      },
      expect: () => [
        const HomeLoaded(
          HomeDashboard(
            stats: HomeDashboardStats(
              dayStreak: 0,
              satsEarned: 0,
              booksRead: 0,
            ),
            circles: [],
          ),
        ),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'emits HomeError when stream emits error',
      build: buildCubit,
      act: (cubit) {
        dashboardController.addError(Exception('stream fail'));
      },
      expect: () => [const HomeError('Exception: stream fail')],
    );

    test('touchBookOpened calls usecase', () async {
      when(
        () => touchDashboardBookOpened.call(any()),
      ).thenAnswer((_) => Future.value());
      final cubit = buildCubit();
      cubit.touchBookOpened('123');
      verify(() => touchDashboardBookOpened.call('123')).called(1);
    });
  });
}
