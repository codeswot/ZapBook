import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/core/domain/entities/book_search_hit.dart';
import 'package:zapbook/core/domain/usecases/book_search_usecases.dart';

class ReaderSearchState extends Equatable {
  const ReaderSearchState({
    this.query = '',
    this.loading = false,
    this.semanticAvailable = true,
    this.hits = const [],
  });

  final String query;
  final bool loading;
  final bool semanticAvailable;
  final List<BookSearchHit> hits;

  ReaderSearchState copyWith({
    String? query,
    bool? loading,
    bool? semanticAvailable,
    List<BookSearchHit>? hits,
  }) {
    return ReaderSearchState(
      query: query ?? this.query,
      loading: loading ?? this.loading,
      semanticAvailable: semanticAvailable ?? this.semanticAvailable,
      hits: hits ?? this.hits,
    );
  }

  @override
  List<Object?> get props => [query, loading, semanticAvailable, hits];
}

@injectable
class ReaderSearchCubit extends Cubit<ReaderSearchState> {
  ReaderSearchCubit(this._search) : super(const ReaderSearchState());

  static const minQueryLength = 3;
  static const maxResults = 30;

  final SearchBooks _search;
  Timer? _debounce;

  void query(String circleDirId, String raw) {
    _debounce?.cancel();
    final q = raw.trim();
    if (q.length < minQueryLength) {
      emit(state.copyWith(query: q, loading: false, hits: const []));
      return;
    }
    emit(state.copyWith(query: q, loading: true));
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final result = await _search(
        q,
        circleDirId: circleDirId,
        limit: maxResults,
      );
      if (isClosed) return;
      final hits = [...result.hits]
        ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
      emit(
        state.copyWith(
          loading: false,
          semanticAvailable: result.semanticAvailable,
          hits: hits,
        ),
      );
    });
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
