import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/features/book_reader/domain/entities/highlight.dart';
import 'package:zapbook/features/book_reader/domain/usecases/highlight_usecases.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/highlights/book_highlights_state.dart';

export 'package:zapbook/features/book_reader/presentation/bloc/highlights/book_highlights_state.dart';

@injectable
class BookHighlightsCubit extends Cubit<BookHighlightsState> {
  BookHighlightsCubit(this._watchBook, this._share, this._delete)
    : super(const BookHighlightsLoading());

  final WatchHighlightsForBookUseCase _watchBook;
  final ShareHighlightToCircleUseCase _share;
  final DeleteHighlightUseCase _delete;

  StreamSubscription<List<Highlight>>? _subscription;

  void load(String bookId) {
    unawaited(_subscription?.cancel());
    emit(const BookHighlightsLoading());
    _subscription = _watchBook(
      bookId,
    ).listen((highlights) => emit(BookHighlightsLoaded(highlights)));
  }

  Future<void> shareToCircle(String highlightId, String groupId) =>
      _share(highlightId: highlightId, groupId: groupId);

  Future<void> deleteHighlight(String highlightId) => _delete(highlightId);

  @override
  Future<void> close() {
    unawaited(_subscription?.cancel());
    return super.close();
  }
}
