import 'dart:async';
import 'dart:isolate';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:sqlite3/sqlite3.dart';

import 'package:zapbook/core/domain/entities/book_search_hit.dart';
import 'package:zapbook/core/identity/account_paths.dart';
import 'package:zapbook/zbf/zbf.dart';

@lazySingleton
class BookSearchIndex {
  BookSearchIndex() : _dbPath = null;

  BookSearchIndex.forPath(String dbPath) : _dbPath = dbPath;

  static const schemaVersion = 2;
  static final RegExp _whitespace = RegExp(r'\s+');

  final _log = logging.Logger('BookSearchIndex');

  String? _dbPath;
  Database? _db;
  Future<void> _writeQueue = Future.value();

  Future<String> _path() async {
    if (_dbPath != null) return _dbPath!;
    final dir = await AccountPaths.supportRoot();
    return _dbPath = '${dir.path}/book_search.db';
  }

  Future<Database> _open() async {
    final existing = _db;
    if (existing != null) return existing;
    final db = sqlite3.open(await _path());
    _initSchema(db);
    return _db = db;
  }

  void close() {
    final db = _db;
    _db = null;
    db?.close();
  }

  static void _initSchema(Database db) {
    db.execute('PRAGMA journal_mode=WAL');
    final version = (db.select('PRAGMA user_version').first.columnAt(0) as num)
        .toInt();
    if (version != schemaVersion) {
      db.execute('DROP TABLE IF EXISTS page_index');
      db.execute('DROP TABLE IF EXISTS indexed_books');
      db.execute('DROP TABLE IF EXISTS indexed_pages');
      db.execute('PRAGMA user_version = $schemaVersion');
    }
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
    db.execute('''
      CREATE TABLE IF NOT EXISTS indexed_pages (
        book_id TEXT NOT NULL,
        page_index INTEGER NOT NULL,
        PRIMARY KEY (book_id, page_index)
      )
    ''');
  }

  Future<void> ensureIndexed(String circleBookId, String zbfPath) {
    final task = _writeQueue.then((_) => _ensureIndexed(circleBookId, zbfPath));
    _writeQueue = task.catchError((Object error, StackTrace stack) {
      _log.warning('Indexing failed for $circleBookId', error, stack);
    });
    return _writeQueue;
  }

  Future<void> _ensureIndexed(String circleBookId, String zbfPath) async {
    final db = await _open();
    final done = db.select('SELECT 1 FROM indexed_books WHERE book_id = ?', [
      circleBookId,
    ]);
    if (done.isNotEmpty) return;

    final processed = db
        .select('SELECT page_index FROM indexed_pages WHERE book_id = ?', [
          circleBookId,
        ])
        .map((r) => (r['page_index'] as num).toInt())
        .toSet();

    final dbPath = await _path();
    final outcome = await Isolate.run(
      () => _indexBookDelta(dbPath, circleBookId, zbfPath, processed),
    );
    if (outcome.newPages == 0) return;

    final processedCount = processed.length + outcome.newPages;
    if (processedCount >= outcome.totalPages) {
      db.execute(
        'INSERT OR REPLACE INTO indexed_books (book_id, page_count, indexed_at) '
        'VALUES (?, ?, ?)',
        [circleBookId, processedCount, DateTime.now().millisecondsSinceEpoch],
      );
    }
    _log.info(
      'Indexed $circleBookId delta '
      '(${outcome.newPages} pages, $processedCount/${outcome.totalPages})',
    );
  }

  static Future<({int newPages, int totalPages})> _indexBookDelta(
    String dbPath,
    String circleBookId,
    String zbfPath,
    Set<int> processedPages,
  ) async {
    final handle = await const ZbfReader().open(zbfPath);
    try {
      final manifest = handle.manifest;

      final db = sqlite3.open(dbPath);
      try {
        _initSchema(db);
        db.execute('BEGIN');
        try {
          final insert = db.prepare(
            'INSERT INTO page_index (book_id, page_number, chapter_title, body) '
            'VALUES (?, ?, ?, ?)',
          );
          final markPage = db.prepare(
            'INSERT OR REPLACE INTO indexed_pages (book_id, page_index) '
            'VALUES (?, ?)',
          );
          var newPages = 0;
          for (var i = 0; i < manifest.pageCount; i++) {
            if (processedPages.contains(i)) continue;
            final page = handle.pageAtOrNull(i);
            if (page == null || page.layoutType == BookLayoutType.processing) {
              continue;
            }
            final body = _pageText(page);
            if (body.isNotEmpty) {
              insert.execute([
                circleBookId,
                page.pageNumber,
                page.chapterTitle,
                body,
              ]);
            }
            markPage.execute([circleBookId, i]);
            newPages++;
          }
          insert.close();
          markPage.close();
          db.execute('COMMIT');
          return (newPages: newPages, totalPages: manifest.pageCount);
        } catch (_) {
          db.execute('ROLLBACK');
          rethrow;
        }
      } finally {
        db.close();
      }
    } finally {
      handle.close();
    }
  }

  static String _pageText(BookPage page) {
    final buffer = StringBuffer();
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
      final trimmed = text.trim();
      if (trimmed.isNotEmpty) {
        if (buffer.isNotEmpty) buffer.write('\n');
        buffer.write(trimmed);
      }
    }
    return buffer.toString();
  }

  Future<List<BookSearchHit>> search(
    String query, {
    String? circleDirId,
    int limit = 30,
  }) async {
    final match = _toMatchQuery(query);
    if (match == null) return const [];
    final db = await _open();
    final filter = circleDirId == null ? '' : 'AND book_id = ?';
    try {
      final rows = db.select(
        '''
        SELECT book_id, page_number, chapter_title,
               snippet(page_index, 3, '${BookSearchHit.highlightStart}', '${BookSearchHit.highlightEnd}', '…', 12) AS excerpt
        FROM page_index
        WHERE page_index MATCH ? $filter
        ORDER BY rank
        LIMIT ?
        ''',
        [match, ?circleDirId, limit],
      );
      return [
        for (final row in rows)
          BookSearchHit(
            circleDirId: row['book_id'] as String,
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
        .split(_whitespace)
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

  Future<bool> isIndexed(String circleBookId) async {
    final db = await _open();
    final rows = db.select('SELECT 1 FROM indexed_books WHERE book_id = ?', [
      circleBookId,
    ]);
    return rows.isNotEmpty;
  }

  Future<void> remove(String circleBookId) async {
    final db = await _open();
    db.execute('DELETE FROM page_index WHERE book_id = ?', [circleBookId]);
    db.execute('DELETE FROM indexed_pages WHERE book_id = ?', [circleBookId]);
    db.execute('DELETE FROM indexed_books WHERE book_id = ?', [circleBookId]);
  }
}
