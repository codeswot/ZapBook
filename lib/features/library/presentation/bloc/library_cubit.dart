import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:rxdart/rxdart.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/features/library/domain/usecases/watch_library_books.dart';
import 'package:zapbook/features/library/domain/usecases/watch_last_opened_library_book.dart';
import 'package:zapbook/features/library/domain/usecases/download_circle_book.dart';
import 'package:zapbook/features/library/presentation/bloc/library_state.dart';

@injectable
class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit(
    this._watchCircleBooks,
    this._watchLastOpenedBook,
    this._downloadCircleBook,
  ) : super(const LibraryLoading()) {
    _init();
  }

  final WatchCircleBooks _watchCircleBooks;
  final WatchLastOpenedLibraryBook _watchLastOpenedBook;
  final DownloadCircleBook _downloadCircleBook;
  StreamSubscription<void>? _subscription;

  void markOpened(String id) {}

  void dismissCirclePrompt() {
    final s = state;
    if (s is LibraryLoaded) {
      emit(s.copyWith(showCirclePrompt: false));
    }
  }

  Future<void> downloadBook(CircleBook book) async {
    final s = state;
    if (s is! LibraryLoaded) return;
    if (s.downloadingBookIds.contains(book.id)) return;

    final newDownloading = Set<String>.from(s.downloadingBookIds)..add(book.id);
    emit(s.copyWith(downloadingBookIds: newDownloading));

    try {
      final success = await _downloadCircleBook(book.circleDirId, book.id);
      if (!success) {
        emit(LibraryError('Failed to download book ${book.title}'));
      }
    } finally {
      final currentState = state;
      if (currentState is LibraryLoaded) {
        final updatedDownloading = Set<String>.from(
          currentState.downloadingBookIds,
        )..remove(book.id);
        emit(currentState.copyWith(downloadingBookIds: updatedDownloading));
      }
    }
  }

  Future<void> _init() async {
    _subscription = Rx.combineLatest2(
      _watchCircleBooks(),
      _watchLastOpenedBook(),
      (books, lastOpened) {
        final currentState = state;
        final downloading = currentState is LibraryLoaded
            ? currentState.downloadingBookIds
            : const <String>{};

        if (books.isEmpty) {
          return const LibraryEmpty();
        } else {
          return LibraryLoaded(
            books,
            lastOpenedBook: lastOpened,
            showCirclePrompt: false,
            downloadingBookIds: downloading,
          );
        }
      },
    ).listen(emit, onError: (Object error) => emit(LibraryError('$error')));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
