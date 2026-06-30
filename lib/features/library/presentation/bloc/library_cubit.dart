import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/features/library/domain/usecases/watch_library_books.dart';
import 'package:zapbook/features/library/presentation/bloc/library_state.dart';

@injectable
class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit(this._watchCircleBooks) : super(const LibraryLoading()) {
    _init();
  }

  final WatchCircleBooks _watchCircleBooks;
  StreamSubscription<List<CircleBook>>? _booksSubscription;

  void markOpened(String id) {}

  void dismissCirclePrompt() {
    final s = state;
    if (s is LibraryLoaded) {
      emit(LibraryLoaded(s.books, showCirclePrompt: false));
    }
  }

  Future<void> deleteBook(String id) async {}

  Future<void> leaveCircle(String id) async {}

  Future<bool> isAdminOf(String bookId) async => false;

  Future<String> ownerLabelFor(String bookId) async => '';

  Future<void> shareBook(String bookId, String memberNpub) async {}

  Future<void> _init() async {
    _booksSubscription = _watchCircleBooks().listen((books) {
      if (books.isEmpty) {
        emit(const LibraryEmpty());
      } else {
        emit(LibraryLoaded(books, showCirclePrompt: false));
      }
    }, onError: (Object error) => emit(LibraryError('$error')));
  }

  @override
  Future<void> close() async {
    await _booksSubscription?.cancel();
    return super.close();
  }
}
