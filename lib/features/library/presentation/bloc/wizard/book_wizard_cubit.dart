import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/core/domain/wizard_data.dart';
import 'package:zapbook/features/library/presentation/bloc/wizard/book_wizard_state.dart';

@injectable
class BookWizardCubit extends Cubit<BookWizardState> {
  BookWizardCubit(
    @factoryParam this._completer,
    @factoryParam String? initialTitle,
  ) : super(
        BookWizardState(title: initialTitle ?? 'Untitled', availableGenres: []),
      );

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
    // Picking logic isn't implemented here yet, but we'll leave it ready
  }

  void removeCoverImage() {
    emit(state.copyWith(coverImage: null));
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
