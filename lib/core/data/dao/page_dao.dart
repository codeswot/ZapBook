import 'dart:convert';
import 'dart:isolate';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:zapbook/core/data/app_database.dart';
import 'package:zapbook/zbf/zbf.dart';

@lazySingleton
class PageDao {
  PageDao(this._appDatabase);

  final AppDatabase _appDatabase;
  final _log = logging.Logger('PageDao');

  Future<Map<int, BookPage>> load(String bookId) async {
    try {
      final db = await _appDatabase.open();
      final rows = db.select(
        'SELECT page_index, json FROM book_pages WHERE book_id = ?',
        [bookId],
      );
      final result = <int, BookPage>{};
      for (final row in rows) {
        try {
          final map = jsonDecode(row['json'] as String) as Map<String, Object?>;
          result[(row['page_index'] as num).toInt()] = BookPage.fromJson(map);
        } on Object catch (error, stack) {
          _log.warning('Skipping corrupt cached page', error, stack);
        }
      }
      return result;
    } on Object catch (error, stack) {
      _log.warning('Page cache load failed for $bookId', error, stack);
      return const {};
    }
  }

  Future<void> saveAll(String bookId, Map<int, BookPage> pages) async {
    if (pages.isEmpty) return;
    try {
      final db = await _appDatabase.open();

      final encodedPages = await Isolate.run(() {
        final result = <int, String>{};
        pages.forEach((index, page) {
          result[index] = jsonEncode(page.toJson());
        });
        return result;
      });

      final statement = db.prepare(
        'INSERT OR REPLACE INTO book_pages (book_id, page_index, json) '
        'VALUES (?, ?, ?)',
      );
      db.execute('BEGIN');
      try {
        encodedPages.forEach((index, jsonStr) {
          statement.execute([bookId, index, jsonStr]);
        });
        db.execute('COMMIT');
      } catch (_) {
        db.execute('ROLLBACK');
        rethrow;
      } finally {
        statement.close();
      }
    } on Object catch (error, stack) {
      _log.warning('Page cache save failed for $bookId', error, stack);
    }
  }

  Future<void> remove(String bookId) async {
    try {
      final db = await _appDatabase.open();
      db.execute('DELETE FROM book_pages WHERE book_id = ?', [bookId]);
    } on Object catch (error, stack) {
      _log.warning('Page cache remove failed for $bookId', error, stack);
    }
  }
}
