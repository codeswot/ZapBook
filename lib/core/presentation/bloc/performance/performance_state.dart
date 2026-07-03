import 'package:equatable/equatable.dart';
import 'package:zapbook/core/services/performance_service.dart';

class PerformanceState extends Equatable {
  const PerformanceState({required this.reduceEffects, required this.mode});

  final bool reduceEffects;
  final PerfMode mode;

  PerformanceState copyWith({bool? reduceEffects, PerfMode? mode}) {
    return PerformanceState(
      reduceEffects: reduceEffects ?? this.reduceEffects,
      mode: mode ?? this.mode,
    );
  }

  @override
  List<Object?> get props => [reduceEffects, mode];
}
