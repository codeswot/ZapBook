import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:zapbook/core/domain/entities/perf_mode.dart';
import 'package:zapbook/core/domain/usecases/performance_usecases.dart';
import 'package:zapbook/core/presentation/bloc/performance/performance_state.dart';

@LazySingleton()
class PerformanceCubit extends Cubit<PerformanceState> {
  PerformanceCubit(
    this._watchPerformanceModeUseCase,
    this._getPerformanceModeUseCase,
    this._setPerformanceModeUseCase,
  ) : super(
        PerformanceState(
          reduceEffects: _getPerformanceModeUseCase.reduceEffects,
          mode: _getPerformanceModeUseCase.mode,
        ),
      ) {
    _watchPerformanceModeUseCase().addListener(_onServiceChanged);
  }

  final WatchPerformanceModeUseCase _watchPerformanceModeUseCase;
  final GetPerformanceModeUseCase _getPerformanceModeUseCase;
  final SetPerformanceModeUseCase _setPerformanceModeUseCase;

  void _onServiceChanged() {
    emit(
      PerformanceState(
        reduceEffects: _getPerformanceModeUseCase.reduceEffects,
        mode: _getPerformanceModeUseCase.mode,
      ),
    );
  }

  Future<void> setMode(PerfMode mode) async {
    await _setPerformanceModeUseCase(mode);
    emit(
      PerformanceState(
        reduceEffects: _getPerformanceModeUseCase.reduceEffects,
        mode: _getPerformanceModeUseCase.mode,
      ),
    );
  }

  @override
  Future<void> close() {
    _watchPerformanceModeUseCase().removeListener(_onServiceChanged);
    return super.close();
  }
}
