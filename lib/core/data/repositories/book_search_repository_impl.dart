import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;

import 'package:zapbook/core/data/library_file_store.dart';
import 'package:zapbook/core/data/search/book_search_index.dart';
import 'package:zapbook/core/data/search/book_vector_index.dart';
import 'package:zapbook/core/domain/entities/book_search_hit.dart';
import 'package:zapbook/core/domain/repositories/book_search_repository.dart';

@LazySingleton(as: BookSearchRepository)
class BookSearchRepositoryImpl implements BookSearchRepository {
  BookSearchRepositoryImpl(this._keyword, this._vectors, this._fileStore);

  final BookSearchIndex _keyword;
  final BookVectorIndex _vectors;
  final LibraryFileStore _fileStore;
  final _log = logging.Logger('BookSearchRepositoryImpl');

  @override
  Future<BlendedSearchResult> search(
    String query, {
    String? circleDirId,
    int limit = 30,
  }) async {
    final keyword = await _keyword.search(
      query,
      circleDirId: circleDirId,
      limit: limit,
    );
    final seen = <String>{
      for (final hit in keyword) '${hit.circleDirId}:${hit.pageNumber}',
    };
    final blended = [...keyword];
    var semanticAvailable = true;
    try {
      final semantic = await _vectors.search(
        query,
        circleDirId: circleDirId,
        limit: limit,
      );
      for (final hit in semantic) {
        if (blended.length >= limit) break;
        if (!seen.add('${hit.circleDirId}:${hit.pageNumber}')) continue;
        blended.add(
          BookSearchHit(
            circleDirId: hit.circleDirId,
            pageNumber: hit.pageNumber,
            chapterTitle: '',
            snippet: hit.text,
          ),
        );
      }
    } on Object catch (error, stack) {
      semanticAvailable = false;
      _log.warning('semantic search failed', error, stack);
    }
    return BlendedSearchResult(
      hits: blended,
      semanticAvailable: semanticAvailable,
    );
  }

  @override
  Future<void> ensureSearchable(String circleDirId, {String? zbfPath}) async {
    final path = zbfPath ?? await _fileStore.zbfPathIfExists(circleDirId);
    if (path == null) return;
    await _keyword.ensureIndexed(circleDirId, path);
    await _vectors.ensureEmbedded(circleDirId, path);
  }

  @override
  Future<void> remove(String circleDirId) async {
    await _keyword.remove(circleDirId);
    await _vectors.remove(circleDirId);
  }
}
