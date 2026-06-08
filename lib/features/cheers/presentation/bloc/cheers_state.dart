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
  const CheersLoaded(this.activities);

  final List<CheersActivity> activities;

  @override
  List<Object?> get props => [activities];
}

final class CheersError extends CheersState {
  const CheersError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
