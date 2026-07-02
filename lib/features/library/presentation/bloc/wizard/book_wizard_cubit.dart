import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/core/services/file_picker_service.dart';
import 'package:zapbook/core/domain/wizard_data.dart';
import 'package:zapbook/features/library/presentation/bloc/wizard/book_wizard_state.dart';

@injectable
class BookWizardCubit extends Cubit<BookWizardState> {
  BookWizardCubit(
    @factoryParam this._completer,
    @factoryParam String? initialTitle,
    this._filePickerService,
  ) : super(
        BookWizardState(
          title: initialTitle ?? 'Untitled',
          availableGenres: const [
            'Fiction',
            'Non-Fiction',
            'Sci-Fi',
            'Fantasy',
            'Mystery',
            'Biography',
            'History',
            'Technology',
            'Science',
            'Romance',
            'Thriller',
            'Self-Help',
            'Business',
            'Philosophy',
            'Art',
          ],
        ),
      );

  final Completer<WizardData> _completer;
  final FilePickerService _filePickerService;

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
    final image = await _filePickerService.pickImage();
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
          genre: state.genre,
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
