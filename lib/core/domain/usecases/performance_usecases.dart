import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:zapbook/core/domain/entities/perf_mode.dart';
import 'package:zapbook/core/domain/repositories/performance_repository.dart';

@injectable
class WatchPerformanceModeUseCase {
  const WatchPerformanceModeUseCase(this._repository);
  final PerformanceRepository _repository;

  ValueListenable<bool> call() => _repository.reduceEffectsListenable;
}

@injectable
class SetPerformanceModeUseCase {
  const SetPerformanceModeUseCase(this._repository);
  final PerformanceRepository _repository;

  Future<void> call(PerfMode mode) => _repository.setMode(mode);
}

@injectable
class GetPerformanceModeUseCase {
  const GetPerformanceModeUseCase(this._repository);
  final PerformanceRepository _repository;

  PerfMode get mode => _repository.mode;
  bool get reduceEffects => _repository.reduceEffects;
}
