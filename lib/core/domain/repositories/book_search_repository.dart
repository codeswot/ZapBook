import 'package:zapbook/core/domain/entities/book_search_hit.dart';

abstract interface class BookSearchRepository {
  Future<BlendedSearchResult> search(
    String query, {
    String? circleDirId,
    int limit,
  });

  Future<void> ensureSearchable(String circleDirId, {String? zbfPath});

  Future<void> remove(String circleDirId);
}
