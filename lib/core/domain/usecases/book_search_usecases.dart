import 'package:injectable/injectable.dart';

import 'package:zapbook/core/domain/entities/book_search_hit.dart';
import 'package:zapbook/core/domain/repositories/book_search_repository.dart';

@injectable
class SearchBooks {
  const SearchBooks(this._repository);

  final BookSearchRepository _repository;

  Future<BlendedSearchResult> call(
    String query, {
    String? circleDirId,
    int limit = 30,
  }) {
    return _repository.search(query, circleDirId: circleDirId, limit: limit);
  }
}

@injectable
class EnsureBookSearchable {
  const EnsureBookSearchable(this._repository);

  final BookSearchRepository _repository;

  Future<void> call(String circleDirId, {String? zbfPath}) {
    return _repository.ensureSearchable(circleDirId, zbfPath: zbfPath);
  }
}
