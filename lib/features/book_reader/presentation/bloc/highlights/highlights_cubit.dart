import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/features/book_reader/domain/entities/highlight.dart';
import 'package:zapbook/features/book_reader/domain/usecases/highlight_usecases.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/highlights/highlights_state.dart';

export 'package:zapbook/features/book_reader/presentation/bloc/highlights/highlights_state.dart';

@injectable
class HighlightsCubit extends Cubit<HighlightsState> {
  HighlightsCubit(
    this._save,
    this._addNote,
    this._share,
    this._delete,
    this._watchPage,
  ) : super(const HighlightsLoading());

  final SaveHighlightUseCase _save;
  final AddNoteUseCase _addNote;
  final ShareHighlightToCircleUseCase _share;
  final DeleteHighlightUseCase _delete;
  final WatchHighlightsForPageUseCase _watchPage;

  StreamSubscription<List<Highlight>>? _subscription;
  String _bookId = '';
  int _pageNumber = -1;

  void openPage({required String bookId, required int pageNumber}) {
    if (_bookId == bookId && _pageNumber == pageNumber) return;
    _bookId = bookId;
    _pageNumber = pageNumber;
    emit(const HighlightsLoading());
    unawaited(_subscription?.cancel());
    _subscription = _watchPage(
      bookId: bookId,
      pageNumber: pageNumber,
    ).listen((highlights) => emit(HighlightsLoaded(highlights)));
  }

  Future<Highlight?> highlight({
    required List<HighlightSpan> spans,
    required String quoteSnapshot,
  }) => _save(
    bookId: _bookId,
    pageNumber: _pageNumber,
    spans: spans,
    quoteSnapshot: quoteSnapshot,
  );

  Future<void> addNote(String highlightId, String note) =>
      _addNote(highlightId: highlightId, note: note);

  Future<void> shareToCircle(String highlightId, String groupId) =>
      _share(highlightId: highlightId, groupId: groupId);

  Future<void> deleteHighlight(String highlightId) => _delete(highlightId);

  @override
  Future<void> close() {
    unawaited(_subscription?.cancel());
    return super.close();
  }
}
