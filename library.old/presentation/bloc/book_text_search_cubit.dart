import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/core/data/search/book_search_index.dart';
import 'package:zapbook/core/data/search/book_vector_index.dart';

@injectable
class BookTextSearchCubit extends Cubit<List<BookSearchHit>> {
  BookTextSearchCubit(this._index, this._vectors) : super(const []);

  static const minQueryLength = 3;
  static const maxResults = 12;

  final BookSearchIndex _index;
  final BookVectorIndex _vectors;
  Timer? _debounce;

  void query(String raw) {
    _debounce?.cancel();
    final q = raw.trim();
    if (q.length < minQueryLength) {
      emit(const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final hits = await _blendedSearch(q);
      if (!isClosed) emit(hits);
    });
  }

  Future<List<BookSearchHit>> _blendedSearch(String q) async {
    final keyword = await _index.search(q, limit: maxResults);
    List<SemanticHit> semantic = const [];
    try {
      semantic = await _vectors.search(q, limit: maxResults);
    } on Object {
      semantic = const [];
    }

    final seen = <String>{
      for (final hit in keyword) '${hit.bookId}:${hit.pageNumber}',
    };
    final blended = [...keyword];
    for (final hit in semantic) {
      if (blended.length >= maxResults) break;
      if (!seen.add('${hit.bookId}:${hit.pageNumber}')) continue;
      blended.add(
        BookSearchHit(
          bookId: hit.bookId,
          pageNumber: hit.pageNumber,
          chapterTitle: '',
          snippet: hit.text,
        ),
      );
    }
    return blended;
  }

  void clear() {
    _debounce?.cancel();
    emit(const []);
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
