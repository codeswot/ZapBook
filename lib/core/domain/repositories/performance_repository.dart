import 'package:flutter/foundation.dart';
import 'package:zapbook/core/domain/entities/perf_mode.dart';

abstract class PerformanceRepository {
  ValueListenable<bool> get reduceEffectsListenable;
  bool get reduceEffects;
  PerfMode get mode;
  Future<void> init();
  Future<void> setMode(PerfMode value);
}
