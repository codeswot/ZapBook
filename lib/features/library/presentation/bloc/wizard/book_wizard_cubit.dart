import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/core/constants/book_genres.dart';
import 'package:zapbook/core/domain/wizard_data.dart';
import 'package:zapbook/features/library/domain/usecases/book_ingestion_usecases.dart';
import 'package:zapbook/features/library/presentation/bloc/wizard/book_wizard_state.dart';

@injectable
class BookWizardCubit extends Cubit<BookWizardState> {
  BookWizardCubit(
    @factoryParam this._completer,
    @factoryParam WizardInitialData? initialData,
    this._pickCoverImage,
  ) : super(
        BookWizardState(
          title: initialData?.title ?? 'Untitled',
          author: initialData?.author,
          availableGenres: bookGenres,
        ),
      );

  final Completer<WizardData> _completer;
  final PickCoverImageUseCase _pickCoverImage;

  void updateTitle(String title) {
    emit(state.copyWith(title: title));
  }

  void updateAuthor(String author) {
    emit(state.copyWith(author: author));
  }

  void toggleGenre(String genre) {
    final genres = List<String>.from(state.selectedGenres);

    if (genres.contains(genre)) {
      genres.remove(genre);
    } else {
      genres.add(genre);
    }

    emit(state.copyWith(selectedGenres: genres));
  }

  Future<void> pickCoverImage() async {
    final image = await _pickCoverImage();
    if (image != null) {
      emit(state.copyWith(coverImage: image));
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
          genres: state.selectedGenres,
        ),
      );
    }
  }

  void cancel() {
    if (!_completer.isCompleted) {
      _completer.completeError('Cancelled by user');
    }
  }
}
