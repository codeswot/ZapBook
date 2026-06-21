import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:sqlite3/sqlite3.dart';

import 'package:zapbook/core/identity/account_paths.dart';
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
    final dir = await AccountPaths.supportRoot();
    return _dbPath = '${dir.path}/book_vectors.db';
  }

  void close() {
    final db = _db;
    _db = null;
    db?.close();
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
        cluster_id INTEGER,
        PRIMARY KEY (book_id, seq)
      )
    ''');
    final columns = db
        .select('PRAGMA table_info("chunks")')
        .map((r) => r['name'] as String)
        .toSet();
    if (!columns.contains('cluster_id')) {
      db.execute('ALTER TABLE chunks ADD COLUMN cluster_id INTEGER');
    }
    db.execute('''
      CREATE TABLE IF NOT EXISTS centroids (
        book_id TEXT NOT NULL,
        cluster_id INTEGER NOT NULL,
        embedding BLOB NOT NULL,
        PRIMARY KEY (book_id, cluster_id)
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

    final inputs = await Isolate.run(() => _chunkAndTokenize(zbfPath));
    if (inputs.isEmpty) return;

    final batch = inputs.map((e) => e.tokens).toList(growable: false);
    final vectors = await _embeddings.embedTokensBatch(batch);

    final clusterCount = _clusterCount(inputs.length);
    List<Float32List> centroids;
    List<int> assignments;
    if (clusterCount > 1) {
      final result = await Isolate.run(() => _runKMeans(vectors, clusterCount));
      centroids = result.centroids;
      assignments = result.assignments;
    } else {
      centroids = const [];
      assignments = List.filled(inputs.length, 0);
    }

    db.execute('BEGIN');
    try {
      db.execute('DELETE FROM chunks WHERE book_id = ?', [bookId]);
      db.execute('DELETE FROM centroids WHERE book_id = ?', [bookId]);
      final insert = db.prepare(
        'INSERT INTO chunks (book_id, page_number, seq, text, embedding, cluster_id) '
        'VALUES (?, ?, ?, ?, ?, ?)',
      );
      for (var i = 0; i < inputs.length; i++) {
        final chunk = inputs[i].chunk;
        final embedding = vectors[i];
        insert.execute([
          bookId,
          chunk.pageNumber,
          chunk.seq,
          chunk.text,
          embedding.buffer.asUint8List(
            embedding.offsetInBytes,
            embedding.lengthInBytes,
          ),
          clusterCount > 1 ? assignments[i] : null,
        ]);
      }
      insert.close();
      if (centroids.isNotEmpty) {
        final insertCentroid = db.prepare(
          'INSERT INTO centroids (book_id, cluster_id, embedding) VALUES (?, ?, ?)',
        );
        for (var i = 0; i < centroids.length; i++) {
          final c = centroids[i];
          insertCentroid.execute([
            bookId,
            i,
            c.buffer.asUint8List(c.offsetInBytes, c.lengthInBytes),
          ]);
        }
        insertCentroid.close();
      }
      db.execute(
        'INSERT OR REPLACE INTO embedded_books (book_id, chunk_count, embedded_at) '
        'VALUES (?, ?, ?)',
        [bookId, inputs.length, DateTime.now().millisecondsSinceEpoch],
      );
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
    _log.info('Embedded $bookId (${inputs.length} chunks)');
  }

  static Future<List<_EmbedInput>> _chunkAndTokenize(String zbfPath) async {
    final handle = await const ZbfReader().open(zbfPath);
    try {
      const chunker = BookChunker();
      final inputs = <_EmbedInput>[];
      for (var i = 0; i < handle.manifest.pageCount; i++) {
        final page = handle.pageAtOrNull(i);
        if (page == null || page.layoutType == BookLayoutType.processing) {
          continue;
        }
        for (final chunk in chunker.chunkPage(page, startSeq: inputs.length)) {
          inputs.add(_EmbedInput(chunk, EmbeddingService.tokenize(chunk.text)));
        }
      }
      return inputs;
    } finally {
      handle.close();
    }
  }

  static int _clusterCount(int chunkCount) {
    if (chunkCount < 20) return 0;
    final k = math.sqrt(chunkCount).ceil().clamp(2, 50);
    return k < chunkCount ? k : 0;
  }

  static ({List<Float32List> centroids, List<int> assignments}) _runKMeans(
    List<Float32List> vectors,
    int k,
  ) {
    final n = vectors.length;
    final d = vectors.first.length;
    final centroids = <Float32List>[];
    final used = <int>{};
    final rng = math.Random(42);
    while (centroids.length < k) {
      final idx = rng.nextInt(n);
      if (used.add(idx)) {
        centroids.add(Float32List.fromList(vectors[idx]));
      }
    }

    final assignments = List.filled(n, 0);
    final accumulators = List.generate(k, (_) => Float32List(d));

    for (var iter = 0; iter < 20; iter++) {
      var changed = false;
      for (var i = 0; i < n; i++) {
        final v = vectors[i];
        var bestCluster = 0;
        var bestDist = -1.0;
        for (var j = 0; j < k; j++) {
          final dist = EmbeddingService.cosine(v, centroids[j]);
          if (dist > bestDist) {
            bestDist = dist;
            bestCluster = j;
          }
        }
        if (assignments[i] != bestCluster) {
          assignments[i] = bestCluster;
          changed = true;
        }
      }
      if (!changed) break;

      for (var j = 0; j < k; j++) {
        accumulators[j].fillRange(0, d, 0.0);
      }
      final counts = List.filled(k, 0);
      for (var i = 0; i < n; i++) {
        final c = assignments[i];
        final acc = accumulators[c];
        final v = vectors[i];
        for (var dim = 0; dim < d; dim++) {
          acc[dim] += v[dim];
        }
        counts[c]++;
      }
      for (var j = 0; j < k; j++) {
        if (counts[j] == 0) continue;
        final acc = accumulators[j];
        final inv = 1.0 / counts[j];
        for (var dim = 0; dim < d; dim++) {
          acc[dim] *= inv;
        }
        centroids[j] = EmbeddingService.normalized(acc);
      }
    }

    return (centroids: centroids, assignments: assignments);
  }

  Future<List<SemanticHit>> search(
    String query, {
    String? bookId,
    int limit = 10,
    double minScore = 0.35,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    await _open();
    final dbPath = await _path();
    final queryVector = await _embeddings.embed(trimmed);
    return Isolate.run(
      () => _scoreChunks(
        dbPath: dbPath,
        queryVector: queryVector,
        bookId: bookId,
        limit: limit,
        minScore: minScore,
      ),
    );
  }

  static List<SemanticHit> _scoreChunks({
    required String dbPath,
    required Float32List queryVector,
    required String? bookId,
    required int limit,
    required double minScore,
  }) {
    final db = sqlite3.open(dbPath);
    try {
      final probedClusters = _probeClusters(db, queryVector, bookId);

      final rows = probedClusters == null
          ? (bookId == null
                ? db.select('SELECT rowid, embedding FROM chunks')
                : db.select(
                    'SELECT rowid, embedding FROM chunks WHERE book_id = ?',
                    [bookId],
                  ))
          : () {
              final placeholders = probedClusters.map((_) => '?').join(',');
              if (bookId == null) {
                return db.select(
                  'SELECT rowid, embedding FROM chunks WHERE cluster_id IN ($placeholders)',
                  probedClusters,
                );
              }
              return db.select(
                'SELECT rowid, embedding FROM chunks '
                'WHERE book_id = ? AND (cluster_id IS NULL OR cluster_id IN ($placeholders))',
                [bookId, ...probedClusters],
              );
            }();

      final topHits = <_ScoredRow>[];
      for (final row in rows) {
        final blob = row['embedding'] as Uint8List;
        final vector = Float32List.view(
          blob.buffer,
          blob.offsetInBytes,
          EmbeddingService.dimensions,
        );
        final score = EmbeddingService.cosine(queryVector, vector);
        if (score < minScore) continue;

        if (topHits.length < limit) {
          topHits.add(_ScoredRow((row['rowid'] as num).toInt(), score));
          if (topHits.length == limit) {
            topHits.sort((a, b) => b.score.compareTo(a.score));
          }
        } else if (score > topHits.last.score) {
          topHits.removeLast();
          var index = 0;
          while (index < topHits.length && topHits[index].score >= score) {
            index++;
          }
          topHits.insert(
            index,
            _ScoredRow((row['rowid'] as num).toInt(), score),
          );
        }
      }

      if (topHits.isEmpty) return const [];
      if (topHits.length < limit) {
        topHits.sort((a, b) => b.score.compareTo(a.score));
      }

      final rowIds = topHits.map((e) => e.rowid).toList();
      final placeholders = List.filled(rowIds.length, '?').join(',');
      final hydrationRows = db.select(
        'SELECT rowid, book_id, page_number, text FROM chunks WHERE rowid IN ($placeholders)',
        rowIds,
      );

      final rowIdToRow = <int, Row>{};
      for (final r in hydrationRows) {
        rowIdToRow[(r['rowid'] as num).toInt()] = r;
      }

      return topHits.map((hit) {
        final r = rowIdToRow[hit.rowid]!;
        return SemanticHit(
          bookId: r['book_id'] as String,
          pageNumber: (r['page_number'] as num).toInt(),
          text: r['text'] as String,
          score: hit.score,
        );
      }).toList();
    } finally {
      db.close();
    }
  }

  static List<int>? _probeClusters(
    Database db,
    Float32List queryVector,
    String? bookId,
  ) {
    final centroidRows = bookId == null
        ? db.select('SELECT cluster_id, embedding FROM centroids')
        : db.select(
            'SELECT cluster_id, embedding FROM centroids WHERE book_id = ?',
            [bookId],
          );
    if (centroidRows.isEmpty) return null;

    final scored = <_ScoredRow>[];
    for (final row in centroidRows) {
      final blob = row['embedding'] as Uint8List;
      final vector = Float32List.view(
        blob.buffer,
        blob.offsetInBytes,
        EmbeddingService.dimensions,
      );
      scored.add(
        _ScoredRow(
          (row['cluster_id'] as num).toInt(),
          EmbeddingService.cosine(queryVector, vector),
        ),
      );
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    final probes = (scored.length / 4).ceil().clamp(1, 5);
    return scored.take(probes).map((c) => c.rowid).toList();
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

class _EmbedInput {
  const _EmbedInput(this.chunk, this.tokens);

  final BookChunk chunk;
  final List<List<int>> tokens;
}

class _ScoredRow {
  const _ScoredRow(this.rowid, this.score);
  final int rowid;
  final double score;
}
