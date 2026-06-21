import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:zapbook/core/performance/performance_service.dart';
import 'package:zapbook/core/performance/performance_state.dart';

@LazySingleton()
class PerformanceCubit extends Cubit<PerformanceState> {
  PerformanceCubit(this._service)
      : super(PerformanceState(
          reduceEffects: _service.reduceEffects,
          mode: _service.mode,
        )) {
    _service.reduceEffectsListenable.addListener(_onServiceChanged);
  }

  final PerformanceService _service;

  void _onServiceChanged() {
    emit(PerformanceState(
      reduceEffects: _service.reduceEffects,
      mode: _service.mode,
    ));
  }

  Future<void> setMode(PerfMode mode) async {
    await _service.setMode(mode);
    emit(PerformanceState(
      reduceEffects: _service.reduceEffects,
      mode: _service.mode,
    ));
  }

  @override
  Future<void> close() {
    _service.reduceEffectsListenable.removeListener(_onServiceChanged);
    return super.close();
  }
}
