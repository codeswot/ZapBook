import 'dart:convert';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;

import 'package:zapbook/core/domain/repositories/book_search_repository.dart';
import 'package:zapbook/core/identity/account_paths.dart';

@lazySingleton
class SearchIndexBackfill {
  SearchIndexBackfill(this._searchRepository);

  final BookSearchRepository _searchRepository;
  final _log = logging.Logger('SearchIndexBackfill');

  Future<void> run() async {
    final root = await AccountPaths.supportRoot();
    final libraryDir = Directory('${root.path}/library');
    if (!libraryDir.existsSync()) return;
    for (final entry in libraryDir.listSync().whereType<Directory>()) {
      final manifestFile = File('${entry.path}/manifest.json');
      if (!manifestFile.existsSync()) continue;
      try {
        final manifest =
            jsonDecode(await manifestFile.readAsString())
                as Map<String, dynamic>;
        final bookId = manifest['id'] as String?;
        if (bookId == null) continue;
        await _searchRepository.ensureSearchable(bookId, zbfPath: entry.path);
      } on Object catch (error, stack) {
        _log.warning('Backfill failed for ${entry.path}', error, stack);
      }
    }
  }
}
