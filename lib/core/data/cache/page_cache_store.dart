import 'dart:convert';
import 'dart:isolate';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:zapbook/zbf/zbf.dart';

@lazySingleton
class PageCacheStore {
  PageCacheStore() : _dbPath = null;

  PageCacheStore.forPath(String dbPath) : _dbPath = dbPath;

  String? _dbPath;
  Database? _db;
  final _log = logging.Logger('PageCacheStore');

  Future<String> _path() async {
    if (_dbPath != null) return _dbPath!;
    final dir = await getApplicationSupportDirectory();
    return _dbPath = '${dir.path}/book_pages.db';
  }

  Future<Database> _open() async {
    final existing = _db;
    if (existing != null) return existing;
    final db = sqlite3.open(await _path());
    db.execute('PRAGMA journal_mode=WAL');
    db.execute('''
      CREATE TABLE IF NOT EXISTS pages (
        book_id TEXT NOT NULL,
        page_index INTEGER NOT NULL,
        json TEXT NOT NULL,
        PRIMARY KEY (book_id, page_index)
      )
    ''');
    return _db = db;
  }

  Future<Map<int, BookPage>> load(String bookId) async {
    try {
      final db = await _open();
      final rows = db.select(
        'SELECT page_index, json FROM pages WHERE book_id = ?',
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
      final db = await _open();
      // Offload JSON encoding to an isolate to prevent UI thread blocking
      final encodedPages = await Isolate.run(() {
        final result = <int, String>{};
        pages.forEach((index, page) {
          result[index] = jsonEncode(page.toJson());
        });
        return result;
      });

      final statement = db.prepare(
        'INSERT OR REPLACE INTO pages (book_id, page_index, json) '
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
      final db = await _open();
      db.execute('DELETE FROM pages WHERE book_id = ?', [bookId]);
    } on Object catch (error, stack) {
      _log.warning('Page cache remove failed for $bookId', error, stack);
    }
  }
}
