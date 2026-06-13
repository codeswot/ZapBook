import 'dart:async';
import 'dart:isolate';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:zapbook/zbf/zbf.dart';

class BookSearchHit {
  const BookSearchHit({
    required this.bookId,
    required this.pageNumber,
    required this.chapterTitle,
    required this.snippet,
  });

  final String bookId;
  final int pageNumber;
  final String chapterTitle;
  final String snippet;
}

@lazySingleton
class BookSearchIndex {
  BookSearchIndex() : _dbPath = null;

  BookSearchIndex.forPath(String dbPath) : _dbPath = dbPath;

  static const highlightStart = '‹';
  static const highlightEnd = '›';

  final _log = logging.Logger('BookSearchIndex');

  String? _dbPath;
  Database? _db;
  Future<void> _writeQueue = Future.value();

  Future<String> _path() async {
    if (_dbPath != null) return _dbPath!;
    final dir = await getApplicationSupportDirectory();
    return _dbPath = '${dir.path}/book_search.db';
  }

  Future<Database> _open() async {
    final existing = _db;
    if (existing != null) return existing;
    final db = sqlite3.open(await _path());
    _initSchema(db);
    return _db = db;
  }

  static void _initSchema(Database db) {
    db.execute('PRAGMA journal_mode=WAL');
    db.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS page_index USING fts5(
        book_id UNINDEXED,
        page_number UNINDEXED,
        chapter_title,
        body,
        tokenize='porter unicode61'
      )
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS indexed_books (
        book_id TEXT PRIMARY KEY,
        page_count INTEGER NOT NULL,
        indexed_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> ensureIndexed(String bookId, String zbfPath) {
    final task = _writeQueue.then((_) => _ensureIndexed(bookId, zbfPath));
    _writeQueue = task.catchError((Object error, StackTrace stack) {
      _log.warning('Indexing failed for $bookId', error, stack);
    });
    return _writeQueue;
  }

  Future<void> _ensureIndexed(String bookId, String zbfPath) async {
    final db = await _open();
    final done = db.select('SELECT 1 FROM indexed_books WHERE book_id = ?', [
      bookId,
    ]);
    if (done.isNotEmpty) return;

    final dbPath = await _path();
    await Isolate.run(() => _indexBook(dbPath, bookId, zbfPath));
    _log.info('Indexed $bookId for search');
  }

  static Future<void> _indexBook(
    String dbPath,
    String bookId,
    String zbfPath,
  ) async {
    final handle = await const ZbfReader().open(zbfPath);
    final manifest = handle.manifest;

    final db = sqlite3.open(dbPath);
    try {
      _initSchema(db);
      db.execute('BEGIN');
      try {
        db.execute('DELETE FROM page_index WHERE book_id = ?', [bookId]);
        final insert = db.prepare(
          'INSERT INTO page_index (book_id, page_number, chapter_title, body) '
          'VALUES (?, ?, ?, ?)',
        );
        var indexedPages = 0;
        for (var i = 0; i < manifest.pageCount; i++) {
          final page = handle.pageAt(i);
          if (page.layoutType == BookLayoutType.processing) continue;
          final body = _pageText(page);
          if (body.isEmpty) continue;
          insert.execute([bookId, page.pageNumber, page.chapterTitle, body]);
          indexedPages++;
        }
        insert.close();
        db.execute(
          'INSERT OR REPLACE INTO indexed_books (book_id, page_count, indexed_at) '
          'VALUES (?, ?, ?)',
          [bookId, indexedPages, DateTime.now().millisecondsSinceEpoch],
        );
        db.execute('COMMIT');
      } catch (_) {
        db.execute('ROLLBACK');
        rethrow;
      }
    } finally {
      db.close();
    }
  }

  static String _pageText(BookPage page) {
    final parts = <String>[];
    for (final block in page.blocks) {
      final text = switch (block) {
        HeadingBlock(:final text) => text,
        ParagraphBlock(:final text) => text,
        PullquoteBlock(:final text) => text,
        CodeBlock(:final text) => text,
        CaptionBlock(:final text) => text,
        ImageBlock(:final altText) => altText,
        _ => '',
      };
      if (text.trim().isNotEmpty) parts.add(text.trim());
    }
    return parts.join('\n');
  }

  Future<List<BookSearchHit>> search(
    String query, {
    String? bookId,
    int limit = 30,
  }) async {
    final match = _toMatchQuery(query);
    if (match == null) return const [];
    final db = await _open();
    final filter = bookId == null ? '' : 'AND book_id = ?';
    try {
      final rows = db.select(
        '''
        SELECT book_id, page_number, chapter_title,
               snippet(page_index, 3, '$highlightStart', '$highlightEnd', '…', 12) AS excerpt
        FROM page_index
        WHERE page_index MATCH ? $filter
        ORDER BY rank
        LIMIT ?
        ''',
        [match, ?bookId, limit],
      );
      return [
        for (final row in rows)
          BookSearchHit(
            bookId: row['book_id'] as String,
            pageNumber: (row['page_number'] as num).toInt(),
            chapterTitle: row['chapter_title'] as String? ?? '',
            snippet: row['excerpt'] as String? ?? '',
          ),
      ];
    } on SqliteException catch (error) {
      _log.warning('Search failed for "$query"', error);
      return const [];
    }
  }

  static String? _toMatchQuery(String raw) {
    final terms = raw
        .trim()
        .split(RegExp(r'\s+'))
        .map((t) => t.replaceAll('"', ''))
        .where((t) => t.isNotEmpty)
        .toList();
    if (terms.isEmpty) return null;
    final quoted = [
      for (var i = 0; i < terms.length; i++)
        i == terms.length - 1 ? '"${terms[i]}" *' : '"${terms[i]}"',
    ];
    return quoted.join(' ');
  }

  Future<bool> isIndexed(String bookId) async {
    final db = await _open();
    final rows = db.select('SELECT 1 FROM indexed_books WHERE book_id = ?', [
      bookId,
    ]);
    return rows.isNotEmpty;
  }

  Future<void> remove(String bookId) async {
    final db = await _open();
    db.execute('DELETE FROM page_index WHERE book_id = ?', [bookId]);
    db.execute('DELETE FROM indexed_books WHERE book_id = ?', [bookId]);
  }
}
