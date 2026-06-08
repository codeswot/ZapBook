import 'package:equatable/equatable.dart';

import 'package:zapbook/features/library/domain/entities/library_book.dart';

sealed class LibraryState extends Equatable {
  const LibraryState();

  @override
  List<Object?> get props => [];
}

final class LibraryLoading extends LibraryState {
  const LibraryLoading();
}

final class LibraryEmpty extends LibraryState {
  const LibraryEmpty();
}

final class LibraryLoaded extends LibraryState {
  const LibraryLoaded(this.books, {this.showCirclePrompt = false});

  final List<LibraryBook> books;
  final bool showCirclePrompt;

  @override
  List<Object?> get props => [books, showCirclePrompt];
}

final class LibraryError extends LibraryState {
  const LibraryError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
