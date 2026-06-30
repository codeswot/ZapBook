import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:rxdart/rxdart.dart';
import 'package:zapbook/features/library/domain/usecases/watch_library_books.dart';
import 'package:zapbook/features/library/domain/usecases/watch_last_opened_library_book.dart';
import 'package:zapbook/features/library/presentation/bloc/library_state.dart';

@injectable
class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit(
    this._watchCircleBooks,
    this._watchLastOpenedBook,
  ) : super(const LibraryLoading()) {
    _init();
  }

  final WatchCircleBooks _watchCircleBooks;
  final WatchLastOpenedLibraryBook _watchLastOpenedBook;
  StreamSubscription<void>? _subscription;

  void markOpened(String id) {}

  void dismissCirclePrompt() {
    final s = state;
    if (s is LibraryLoaded) {
      emit(LibraryLoaded(
        s.books,
        lastOpenedBook: s.lastOpenedBook,
        showCirclePrompt: false,
      ));
    }
  }

  Future<void> deleteBook(String id) async {}

  Future<void> leaveCircle(String id) async {}

  Future<bool> isAdminOf(String bookId) async => false;

  Future<String> ownerLabelFor(String bookId) async => '';

  Future<void> shareBook(String bookId, String memberNpub) async {}

  Future<void> _init() async {
    _subscription = Rx.combineLatest2(
      _watchCircleBooks(),
      _watchLastOpenedBook(),
      (books, lastOpened) {
        if (books.isEmpty) {
          emit(const LibraryEmpty());
        } else {
          emit(LibraryLoaded(books, lastOpenedBook: lastOpened, showCirclePrompt: false));
        }
      },
    ).listen((_) {}, onError: (Object error) => emit(LibraryError('$error')));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
