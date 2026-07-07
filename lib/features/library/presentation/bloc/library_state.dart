import 'package:equatable/equatable.dart';

import 'package:zapbook/core/domain/entities/circle_book.dart';

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
  const LibraryLoaded(
    this.books, {
    this.lastOpenedBook,
    this.showCirclePrompt = false,
  });

  final List<CircleBook> books;
  final CircleBook? lastOpenedBook;
  final bool showCirclePrompt;

  LibraryLoaded copyWith({
    List<CircleBook>? books,
    CircleBook? lastOpenedBook,
    bool? showCirclePrompt,
  }) {
    return LibraryLoaded(
      books ?? this.books,
      lastOpenedBook: lastOpenedBook ?? this.lastOpenedBook,
      showCirclePrompt: showCirclePrompt ?? this.showCirclePrompt,
    );
  }

  @override
  List<Object?> get props => [books, lastOpenedBook, showCirclePrompt];
}

final class LibraryError extends LibraryState {
  const LibraryError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
