import 'package:equatable/equatable.dart';
import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';

abstract class CheersState extends Equatable {
  const CheersState();

  @override
  List<Object?> get props => [];
}

final class CheersLoading extends CheersState {
  const CheersLoading();
}

final class CheersLoaded extends CheersState {
  const CheersLoaded({required this.activities, required this.activeFilter});

  final List<CheersActivity> activities;
  final String activeFilter;

  @override
  List<Object?> get props => [activities, activeFilter];
}

final class CheersError extends CheersState {
  const CheersError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

abstract class CheersActionState extends CheersState {
  const CheersActionState();
}

final class CheersZapSuccess extends CheersActionState {
  const CheersZapSuccess(this.message);
  final String message;
  @override
  List<Object?> get props => [message, DateTime.now().millisecondsSinceEpoch];
}

final class CheersZapInfo extends CheersActionState {
  const CheersZapInfo(this.message);
  final String message;
  @override
  List<Object?> get props => [message, DateTime.now().millisecondsSinceEpoch];
}

final class CheersZapError extends CheersActionState {
  const CheersZapError(this.message);
  final String message;
  @override
  List<Object?> get props => [message, DateTime.now().millisecondsSinceEpoch];
}

final class CheersNudgeSuccess extends CheersActionState {
  const CheersNudgeSuccess(this.message);
  final String message;
  @override
  List<Object?> get props => [message, DateTime.now().millisecondsSinceEpoch];
}

final class CheersNudgeRequired extends CheersActionState {
  const CheersNudgeRequired(this.activity, this.title, this.message);
  final CheersActivity activity;
  final String title;
  final String message;
  @override
  List<Object?> get props => [activity, title, message, DateTime.now().millisecondsSinceEpoch];
}

final class CheersNudgeSetupRequired extends CheersActionState {
  const CheersNudgeSetupRequired(this.activity, this.title, this.message);
  final CheersActivity activity;
  final String title;
  final String message;
  @override
  List<Object?> get props => [activity, title, message, DateTime.now().millisecondsSinceEpoch];
}
