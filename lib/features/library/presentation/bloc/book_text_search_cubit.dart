import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/core/domain/entities/book_search_hit.dart';
import 'package:zapbook/core/domain/usecases/book_search_usecases.dart';

@injectable
class BookTextSearchCubit extends Cubit<List<BookSearchHit>> {
  BookTextSearchCubit(this._search) : super(const []);

  static const minQueryLength = 3;
  static const maxResults = 12;

  final SearchBooks _search;
  Timer? _debounce;

  void query(String raw) {
    _debounce?.cancel();
    final q = raw.trim();
    if (q.length < minQueryLength) {
      emit(const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final result = await _search(q, limit: maxResults);
      if (!isClosed) emit(result.hits);
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
