import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/core/data/search/book_search_index.dart';

@injectable
class BookTextSearchCubit extends Cubit<List<BookSearchHit>> {
  BookTextSearchCubit(this._index) : super(const []);

  static const minQueryLength = 3;

  final BookSearchIndex _index;
  Timer? _debounce;

  void query(String raw) {
    _debounce?.cancel();
    final q = raw.trim();
    if (q.length < minQueryLength) {
      emit(const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final hits = await _index.search(q);
      if (!isClosed) emit(hits);
    });
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
