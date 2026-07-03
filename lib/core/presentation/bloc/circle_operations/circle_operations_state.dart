import 'package:equatable/equatable.dart';

sealed class CircleOperationsState extends Equatable {
  const CircleOperationsState();

  @override
  List<Object?> get props => [];
}

class CircleOperationsInitial extends CircleOperationsState {
  const CircleOperationsInitial();
}

class CircleOperationsLoading extends CircleOperationsState {
  const CircleOperationsLoading();
}

class CircleOperationsSuccess extends CircleOperationsState {
  const CircleOperationsSuccess();
}

class CircleOperationsFailure extends CircleOperationsState {
  const CircleOperationsFailure(this.error);
  final String error;

  @override
  List<Object?> get props => [error];
}
