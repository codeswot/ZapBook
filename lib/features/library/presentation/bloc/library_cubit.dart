import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/features/library/domain/usecases/backfill_library.dart';
import 'package:zapbook/features/library/domain/usecases/touch_book_opened.dart';
import 'package:zapbook/features/library/domain/usecases/watch_library_books.dart';
import 'package:zapbook/features/library/presentation/bloc/library_state.dart';

@injectable
class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit(
    this._watchLibraryBooks,
    this._backfillLibrary,
    this._touchBookOpened,
  ) : super(const LibraryLoading()) {
    _init();
  }

  final WatchLibraryBooks _watchLibraryBooks;
  final BackfillLibrary _backfillLibrary;
  final TouchBookOpened _touchBookOpened;
  StreamSubscription<List<LibraryBook>>? _subscription;

  void markOpened(String id) => _touchBookOpened(id);

  Future<void> _init() async {
    try {
      await _backfillLibrary();
    } on Object catch (error) {
      emit(LibraryError('$error'));
    }
    _subscription = _watchLibraryBooks().listen(
      (books) =>
          emit(books.isEmpty ? const LibraryEmpty() : LibraryLoaded(books)),
      onError: (Object error) => emit(LibraryError('$error')),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
