import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/core/data/datasources/genre_datasource.dart';
import 'package:zapbook/core/services/file_picker_service.dart';
import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/features/library/domain/usecases/update_book_metadata.dart';
import 'package:zapbook/features/library/presentation/bloc/book_edit_state.dart';

@injectable
class BookEditCubit extends Cubit<BookEditState> {
  BookEditCubit(GenreDataSource genres, this._filePicker, this._updateBookMetadata, LibraryBook book)
    : super(BookEditState(
        book: book,
        title: book.title,
        author: book.author,
        genre: book.genre,
        genres: genres.getGenres(),
      ));

  final FilePickerService _filePicker;
  final UpdateBookMetadata _updateBookMetadata;

  void setTitle(String title) => emit(state.copyWith(title: title));
  void setAuthor(String author) => emit(state.copyWith(author: author));
  void setGenre(String? genre) => emit(state.copyWith(genre: genre));

  Future<void> pickCover() async {
    final bytes = await _filePicker.pickImage();
    if (bytes != null) emit(state.copyWith(newCover: bytes));
  }

  Future<LibraryBook?> save() async {
    emit(state.copyWith(saving: true));
    try {
      final updated = await _updateBookMetadata(
        state.book.id,
        title: state.title,
        author: state.author,
        genre: state.genre,
        coverImage: state.newCover,
      );
      emit(state.copyWith(saving: false));
      return updated;
    } on Exception {
      emit(state.copyWith(saving: false, error: 'Failed to save changes'));
      return null;
    }
  }
}
