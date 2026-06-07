import 'dart:typed_data';

import 'package:zapbook/features/library/domain/entities/library_book.dart';

class BookEditState {
  final LibraryBook book;
  final String title;
  final String author;
  final String? genre;
  final List<String> genres;
  final Uint8List? newCover;
  final bool saving;
  final String? error;

  const BookEditState({
    required this.book,
    required this.title,
    required this.author,
    this.genre,
    required this.genres,
    this.newCover,
    this.saving = false,
    this.error,
  });

  BookEditState copyWith({
    LibraryBook? book,
    String? title,
    String? author,
    String? genre,
    List<String>? genres,
    Uint8List? newCover,
    bool? saving,
    String? error,
    bool clearError = false,
    bool clearCover = false,
  }) {
    return BookEditState(
      book: book ?? this.book,
      title: title ?? this.title,
      author: author ?? this.author,
      genre: genre ?? this.genre,
      genres: genres ?? this.genres,
      newCover: clearCover ? null : (newCover ?? this.newCover),
      saving: saving ?? this.saving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
