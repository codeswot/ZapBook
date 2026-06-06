import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/core/services/file_picker_service.dart';
import 'package:zapbook/core/data/datasources/genre_datasource.dart';
import 'package:zapbook/core/domain/wizard_data.dart';
import 'package:zapbook/features/library/presentation/bloc/wizard/book_wizard_state.dart';

@injectable
class BookWizardCubit extends Cubit<BookWizardState> {
  BookWizardCubit(
    this._filePickerService,
    this._genreDataSource,
    @factoryParam this._completer,
    @factoryParam String? initialTitle,
  ) : super(BookWizardState(title: initialTitle ?? 'Untitled')) {
    final genres = _genreDataSource.getGenres();
    emit(state.copyWith(availableGenres: genres));
  }

  final FilePickerService _filePickerService;
  final GenreDataSource _genreDataSource;
  final Completer<WizardData> _completer;

  void updateTitle(String title) {
    emit(state.copyWith(title: title));
  }

  void updateAuthor(String author) {
    emit(state.copyWith(author: author));
  }

  void updateGenre(String genre) {
    emit(state.copyWith(genre: genre));
  }

  Future<void> pickCoverImage() async {
    final bytes = await _filePickerService.pickImage();
    if (bytes != null) {
      emit(state.copyWith(coverImage: bytes));
    }
  }

  void removeCoverImage() {
    emit(state.copyWith(clearCover: true));
  }

  void submit() {
    if (!_completer.isCompleted) {
      _completer.complete(
        WizardData(
          title: state.title,
          coverImage: state.coverImage,
          author: state.author,
          genre: state.genre,
        ),
      );
    }
  }

  void cancel() {
    if (!_completer.isCompleted) {
      _completer.complete(
        WizardData(
          title: state.title,
          coverImage: state.coverImage,
          author: state.author,
          genre: state.genre,
        ),
      );
    }
  }
}
