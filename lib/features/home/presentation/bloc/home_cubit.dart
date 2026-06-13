import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:zapbook/features/home/domain/usecases/touch_dashboard_book_opened.dart';
import 'package:zapbook/features/home/domain/usecases/watch_home_dashboard.dart';
import 'package:zapbook/features/home/presentation/bloc/home_state.dart';

@injectable
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._watchHomeDashboard, this._touchDashboardBookOpened)
    : super(const HomeLoading()) {
    _subscribe();
  }

  final WatchHomeDashboard _watchHomeDashboard;
  final TouchDashboardBookOpened _touchDashboardBookOpened;

  StreamSubscription? _subscription;

  void _subscribe() {
    _subscription = _watchHomeDashboard().listen(
      (dashboard) => emit(HomeLoaded(dashboard)),
      onError: (Object error) => emit(HomeError(error.toString())),
    );
  }

  void touchBookOpened(String bookId) {
    _touchDashboardBookOpened(bookId);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
