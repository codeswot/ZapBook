import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:zapbook/core/data/search/book_chunker.dart';
import 'package:zapbook/core/data/search/embedding_service.dart';
import 'package:zapbook/zbf/zbf.dart';

class SemanticHit {
  const SemanticHit({
    required this.bookId,
    required this.pageNumber,
    required this.text,
    required this.score,
  });

  final String bookId;
  final int pageNumber;
  final String text;
  final double score;
}

@lazySingleton
class BookVectorIndex {
  BookVectorIndex(this._embeddings) : _dbPath = null;

  BookVectorIndex.forPath(this._embeddings, String dbPath) : _dbPath = dbPath;

  final EmbeddingService _embeddings;
  final _log = logging.Logger('BookVectorIndex');

  String? _dbPath;
  Database? _db;
  Future<void> _writeQueue = Future.value();

  Future<String> _path() async {
    if (_dbPath != null) return _dbPath!;
    final dir = await getApplicationSupportDirectory();
    return _dbPath = '${dir.path}/book_vectors.db';
  }

  Future<Database> _open() async {
    final existing = _db;
    if (existing != null) return existing;
    final db = sqlite3.open(await _path());
    db.execute('PRAGMA journal_mode=WAL');
    db.execute('''
      CREATE TABLE IF NOT EXISTS chunks (
        book_id TEXT NOT NULL,
        page_number INTEGER NOT NULL,
        seq INTEGER NOT NULL,
        text TEXT NOT NULL,
        embedding BLOB NOT NULL,
        PRIMARY KEY (book_id, seq)
      )
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS embedded_books (
        book_id TEXT PRIMARY KEY,
        chunk_count INTEGER NOT NULL,
        embedded_at INTEGER NOT NULL
      )
    ''');
    return _db = db;
  }

  Future<void> ensureEmbedded(String bookId, String zbfPath) {
    final task = _writeQueue.then((_) => _ensureEmbedded(bookId, zbfPath));
    _writeQueue = task.catchError((Object error, StackTrace stack) {
      _log.warning('Embedding failed for $bookId', error, stack);
    });
    return _writeQueue;
  }

  Future<void> _ensureEmbedded(String bookId, String zbfPath) async {
    final db = await _open();
    final done = db.select('SELECT 1 FROM embedded_books WHERE book_id = ?', [
      bookId,
    ]);
    if (done.isNotEmpty) return;

    final chunks = await Isolate.run(() => _chunkBook(zbfPath));
    if (chunks.isEmpty) return;

    final vectors = <Float32List>[];
    for (final chunk in chunks) {
      vectors.add(await _embeddings.embed(chunk.text));
    }

    db.execute('BEGIN');
    try {
      db.execute('DELETE FROM chunks WHERE book_id = ?', [bookId]);
      final insert = db.prepare(
        'INSERT INTO chunks (book_id, page_number, seq, text, embedding) '
        'VALUES (?, ?, ?, ?, ?)',
      );
      for (var i = 0; i < chunks.length; i++) {
        final embedding = vectors[i];
        insert.execute([
          bookId,
          chunks[i].pageNumber,
          chunks[i].seq,
          chunks[i].text,
          embedding.buffer.asUint8List(
            embedding.offsetInBytes,
            embedding.lengthInBytes,
          ),
        ]);
      }
      insert.close();
      db.execute(
        'INSERT OR REPLACE INTO embedded_books (book_id, chunk_count, embedded_at) '
        'VALUES (?, ?, ?)',
        [bookId, chunks.length, DateTime.now().millisecondsSinceEpoch],
      );
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
    _log.info('Embedded $bookId (${chunks.length} chunks)');
  }

  static Future<List<BookChunk>> _chunkBook(String zbfPath) async {
    final handle = await const ZbfReader().open(zbfPath);
    const chunker = BookChunker();
    final chunks = <BookChunk>[];
    for (var i = 0; i < handle.manifest.pageCount; i++) {
      final page = handle.pageAt(i);
      if (page.layoutType == BookLayoutType.processing) continue;
      chunks.addAll(chunker.chunkPage(page, startSeq: chunks.length));
    }
    return chunks;
  }

  Future<List<SemanticHit>> search(
    String query, {
    String? bookId,
    int limit = 10,
    double minScore = 0.35,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final db = await _open();
    final queryVector = await _embeddings.embed(trimmed);

    final rows = bookId == null
        ? db.select('SELECT book_id, page_number, text, embedding FROM chunks')
        : db.select(
            'SELECT book_id, page_number, text, embedding FROM chunks '
            'WHERE book_id = ?',
            [bookId],
          );

    final scored = <SemanticHit>[];
    for (final row in rows) {
      final blob = row['embedding'] as Uint8List;
      final vector = Float32List.view(
        blob.buffer,
        blob.offsetInBytes,
        EmbeddingService.dimensions,
      );
      final score = EmbeddingService.cosine(queryVector, vector);
      if (score < minScore) continue;
      scored.add(
        SemanticHit(
          bookId: row['book_id'] as String,
          pageNumber: (row['page_number'] as num).toInt(),
          text: row['text'] as String,
          score: score,
        ),
      );
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.length > limit ? scored.sublist(0, limit) : scored;
  }

  Future<bool> isEmbedded(String bookId) async {
    final db = await _open();
    return db.select('SELECT 1 FROM embedded_books WHERE book_id = ?', [
      bookId,
    ]).isNotEmpty;
  }

  Future<void> remove(String bookId) async {
    final db = await _open();
    db.execute('DELETE FROM chunks WHERE book_id = ?', [bookId]);
    db.execute('DELETE FROM embedded_books WHERE book_id = ?', [bookId]);
  }
}
