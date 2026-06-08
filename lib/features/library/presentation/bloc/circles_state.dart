import 'package:equatable/equatable.dart';

import 'package:zapbook/features/library/domain/entities/library_book.dart';

sealed class CirclesState extends Equatable {
  const CirclesState();

  @override
  List<Object?> get props => [];
}

final class CirclesLoading extends CirclesState {
  const CirclesLoading();
}

final class CirclesEmpty extends CirclesState {
  const CirclesEmpty();
}

final class CirclesLoaded extends CirclesState {
  const CirclesLoaded(this.circles);

  final List<LibraryBook> circles;

  @override
  List<Object?> get props => [circles];
}

final class CirclesError extends CirclesState {
  const CirclesError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
