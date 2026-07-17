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
    required this.circleDirId,
    required this.pageNumber,
    required this.text,
    required this.score,
  });

  final String circleDirId;
  final int pageNumber;
  final String text;
  final double score;
}

@lazySingleton
class BookVectorIndex {
  BookVectorIndex(this._embeddings) : _dbPath = null;

  BookVectorIndex.forPath(this._embeddings, String dbPath) : _dbPath = dbPath;

  static const schemaVersion = 2;

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
    final version = (db.select('PRAGMA user_version').first.columnAt(0) as num)
        .toInt();
    if (version != schemaVersion) {
      db.execute('DROP TABLE IF EXISTS chunks');
      db.execute('DROP TABLE IF EXISTS centroids');
      db.execute('DROP TABLE IF EXISTS embedded_books');
      db.execute('DROP TABLE IF EXISTS embedded_pages');
      db.execute('PRAGMA user_version = $schemaVersion');
    }
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
    db.execute('''
      CREATE TABLE IF NOT EXISTS centroids (
        book_id TEXT NOT NULL,
        cluster_id INTEGER NOT NULL,
        embedding BLOB NOT NULL,
        PRIMARY KEY (book_id, cluster_id)
      )
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS embedded_pages (
        book_id TEXT NOT NULL,
        page_index INTEGER NOT NULL,
        PRIMARY KEY (book_id, page_index)
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

  Future<void> ensureEmbedded(String circleBookId, String zbfPath) {
    final task = _writeQueue.then(
      (_) => _ensureEmbedded(circleBookId, zbfPath),
    );
    _writeQueue = task.catchError((Object error, StackTrace stack) {
      _log.warning('Embedding failed for $circleBookId', error, stack);
    });
    return _writeQueue;
  }

  Future<void> _ensureEmbedded(String circleBookId, String zbfPath) async {
    final db = await _open();
    final done = db.select('SELECT 1 FROM embedded_books WHERE book_id = ?', [
      circleBookId,
    ]);
    if (done.isNotEmpty) return;

    final processed = db
        .select('SELECT page_index FROM embedded_pages WHERE book_id = ?', [
          circleBookId,
        ])
        .map((r) => (r['page_index'] as num).toInt())
        .toSet();

    final delta = await Isolate.run(
      () => _chunkAndTokenizeDelta(zbfPath, processed),
    );
    if (delta.pageIndexes.isEmpty) return;

    var seq =
        (db.select(
                  'SELECT COALESCE(MAX(seq), -1) AS max_seq FROM chunks WHERE book_id = ?',
                  [circleBookId],
                ).first['max_seq']
                as num)
            .toInt() +
        1;

    final batch = delta.inputs.map((e) => e.tokens).toList(growable: false);
    final vectors = batch.isEmpty
        ? const <Float32List>[]
        : await _embeddings.embedTokensBatch(batch);

    db.execute('BEGIN');
    try {
      final insert = db.prepare(
        'INSERT OR REPLACE INTO chunks (book_id, page_number, seq, text, embedding, cluster_id) '
        'VALUES (?, ?, ?, ?, ?, NULL)',
      );
      for (var i = 0; i < delta.inputs.length; i++) {
        final chunk = delta.inputs[i].chunk;
        final embedding = vectors[i];
        insert.execute([
          circleBookId,
          chunk.pageNumber,
          seq++,
          chunk.text,
          embedding.buffer.asUint8List(
            embedding.offsetInBytes,
            embedding.lengthInBytes,
          ),
        ]);
      }
      insert.close();
      final markPage = db.prepare(
        'INSERT OR REPLACE INTO embedded_pages (book_id, page_index) VALUES (?, ?)',
      );
      for (final pageIndex in delta.pageIndexes) {
        markPage.execute([circleBookId, pageIndex]);
      }
      markPage.close();
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }

    final processedCount = processed.length + delta.pageIndexes.length;
    if (processedCount >= delta.totalPages) {
      await _finalizeBook(db, circleBookId);
    }
    _log.info(
      'Embedded $circleBookId delta '
      '(${delta.inputs.length} chunks, $processedCount/${delta.totalPages} pages)',
    );
  }

  Future<void> _finalizeBook(Database db, String circleBookId) async {
    final rows = db.select(
      'SELECT seq, embedding FROM chunks WHERE book_id = ? ORDER BY seq',
      [circleBookId],
    );
    final seqs = <int>[];
    final vectors = <Float32List>[];
    for (final row in rows) {
      seqs.add((row['seq'] as num).toInt());
      final blob = row['embedding'] as Uint8List;
      vectors.add(
        Float32List.fromList(
          Float32List.view(
            blob.buffer,
            blob.offsetInBytes,
            EmbeddingService.dimensions,
          ),
        ),
      );
    }

    final clusterCount = _clusterCount(vectors.length);
    db.execute('BEGIN');
    try {
      db.execute('DELETE FROM centroids WHERE book_id = ?', [circleBookId]);
      if (clusterCount > 1) {
        final result = await Isolate.run(
          () => _runKMeans(vectors, clusterCount),
        );
        final assign = db.prepare(
          'UPDATE chunks SET cluster_id = ? WHERE book_id = ? AND seq = ?',
        );
        for (var i = 0; i < seqs.length; i++) {
          assign.execute([result.assignments[i], circleBookId, seqs[i]]);
        }
        assign.close();
        final insertCentroid = db.prepare(
          'INSERT INTO centroids (book_id, cluster_id, embedding) VALUES (?, ?, ?)',
        );
        for (var i = 0; i < result.centroids.length; i++) {
          final c = result.centroids[i];
          insertCentroid.execute([
            circleBookId,
            i,
            c.buffer.asUint8List(c.offsetInBytes, c.lengthInBytes),
          ]);
        }
        insertCentroid.close();
      }
      db.execute(
        'INSERT OR REPLACE INTO embedded_books (book_id, chunk_count, embedded_at) '
        'VALUES (?, ?, ?)',
        [circleBookId, vectors.length, DateTime.now().millisecondsSinceEpoch],
      );
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  static Future<_EmbedDelta> _chunkAndTokenizeDelta(
    String zbfPath,
    Set<int> processedPages,
  ) async {
    final handle = await const ZbfReader().open(zbfPath);
    try {
      const chunker = BookChunker();
      final inputs = <_EmbedInput>[];
      final pageIndexes = <int>[];
      for (var i = 0; i < handle.manifest.pageCount; i++) {
        if (processedPages.contains(i)) continue;
        final page = handle.pageAtOrNull(i);
        if (page == null || page.layoutType == BookLayoutType.processing) {
          continue;
        }
        pageIndexes.add(i);
        for (final chunk in chunker.chunkPage(page, startSeq: inputs.length)) {
          inputs.add(_EmbedInput(chunk, EmbeddingService.tokenize(chunk.text)));
        }
      }
      return _EmbedDelta(
        inputs: inputs,
        pageIndexes: pageIndexes,
        totalPages: handle.manifest.pageCount,
      );
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
    String? circleDirId,
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
        circleBookId: circleDirId,
        limit: limit,
        minScore: minScore,
      ),
    );
  }

  static List<SemanticHit> _scoreChunks({
    required String dbPath,
    required Float32List queryVector,
    required String? circleBookId,
    required int limit,
    required double minScore,
  }) {
    final db = sqlite3.open(dbPath);
    try {
      final probes = _probeClusters(db, queryVector, circleBookId);
      final rows = _candidateRows(db, probes, circleBookId);

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
          circleDirId: r['book_id'] as String,
          pageNumber: (r['page_number'] as num).toInt(),
          text: r['text'] as String,
          score: hit.score,
        );
      }).toList();
    } finally {
      db.close();
    }
  }

  static ResultSet _candidateRows(
    Database db,
    List<_BookProbes>? probes,
    String? circleBookId,
  ) {
    if (probes == null) {
      return circleBookId == null
          ? db.select('SELECT rowid, embedding FROM chunks')
          : db.select('SELECT rowid, embedding FROM chunks WHERE book_id = ?', [
              circleBookId,
            ]);
    }
    if (circleBookId != null) {
      final probe = probes.first;
      final placeholders = probe.clusterIds.map((_) => '?').join(',');
      return db.select(
        'SELECT rowid, embedding FROM chunks '
        'WHERE book_id = ? AND (cluster_id IS NULL OR cluster_id IN ($placeholders))',
        [circleBookId, ...probe.clusterIds],
      );
    }
    final terms = <String>['cluster_id IS NULL'];
    final args = <Object>[];
    for (final probe in probes) {
      final placeholders = probe.clusterIds.map((_) => '?').join(',');
      terms.add('(book_id = ? AND cluster_id IN ($placeholders))');
      args
        ..add(probe.bookId)
        ..addAll(probe.clusterIds);
    }
    return db.select(
      'SELECT rowid, embedding FROM chunks WHERE ${terms.join(' OR ')}',
      args,
    );
  }

  static List<_BookProbes>? _probeClusters(
    Database db,
    Float32List queryVector,
    String? circleBookId,
  ) {
    final centroidRows = circleBookId == null
        ? db.select('SELECT book_id, cluster_id, embedding FROM centroids')
        : db.select(
            'SELECT book_id, cluster_id, embedding FROM centroids WHERE book_id = ?',
            [circleBookId],
          );
    if (centroidRows.isEmpty) return null;

    final byBook = <String, List<_ScoredRow>>{};
    for (final row in centroidRows) {
      final blob = row['embedding'] as Uint8List;
      final vector = Float32List.view(
        blob.buffer,
        blob.offsetInBytes,
        EmbeddingService.dimensions,
      );
      byBook
          .putIfAbsent(row['book_id'] as String, () => [])
          .add(
            _ScoredRow(
              (row['cluster_id'] as num).toInt(),
              EmbeddingService.cosine(queryVector, vector),
            ),
          );
    }

    final result = <_BookProbes>[];
    for (final entry in byBook.entries) {
      final scored = entry.value..sort((a, b) => b.score.compareTo(a.score));
      final probeCount = (scored.length / 4).ceil().clamp(1, 5);
      result.add(
        _BookProbes(
          entry.key,
          scored.take(probeCount).map((c) => c.rowid).toList(),
        ),
      );
    }
    return result;
  }

  Future<bool> isEmbedded(String circleBookId) async {
    final db = await _open();
    return db.select('SELECT 1 FROM embedded_books WHERE book_id = ?', [
      circleBookId,
    ]).isNotEmpty;
  }

  Future<void> remove(String circleBookId) async {
    final db = await _open();
    db.execute('DELETE FROM chunks WHERE book_id = ?', [circleBookId]);
    db.execute('DELETE FROM centroids WHERE book_id = ?', [circleBookId]);
    db.execute('DELETE FROM embedded_pages WHERE book_id = ?', [circleBookId]);
    db.execute('DELETE FROM embedded_books WHERE book_id = ?', [circleBookId]);
  }
}

class _EmbedDelta {
  const _EmbedDelta({
    required this.inputs,
    required this.pageIndexes,
    required this.totalPages,
  });

  final List<_EmbedInput> inputs;
  final List<int> pageIndexes;
  final int totalPages;
}

class _EmbedInput {
  const _EmbedInput(this.chunk, this.tokens);

  final BookChunk chunk;
  final List<List<int>> tokens;
}

class _BookProbes {
  const _BookProbes(this.bookId, this.clusterIds);

  final String bookId;
  final List<int> clusterIds;
}

class _ScoredRow {
  const _ScoredRow(this.rowid, this.score);
  final int rowid;
  final double score;
}
