import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:zapbook/core/domain/repositories/book_download_repository.dart';
import 'package:zapbook/core/domain/repositories/book_search_repository.dart';

@injectable
class DownloadCircleBook {
  const DownloadCircleBook(this._repository, this._searchRepository);

  final BookDownloadRepository _repository;
  final BookSearchRepository _searchRepository;

  Future<bool> call(String groupId, String circleDirId) async {
    final ok = await _repository.fetchAndDownloadBook(groupId, circleDirId);
    if (ok) {
      unawaited(_searchRepository.ensureSearchable(circleDirId));
    }
    return ok;
  }
}
