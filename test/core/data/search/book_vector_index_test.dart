import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:zapbook/core/data/search/book_chunker.dart';
import 'package:zapbook/core/data/search/book_vector_index.dart';
import 'package:zapbook/core/data/search/embedding_service.dart';
import 'package:zapbook/zbf/zbf.dart';

class FakeEmbeddingService extends EmbeddingService {
  @override
  Future<List<Float32List>> embedTokensBatch(
    List<List<List<int>>> batch,
  ) async {
    return [
      for (final pieces in batch)
        () {
          final vector = Float32List(EmbeddingService.dimensions);
          for (final tokens in pieces) {
            for (final token in tokens) {
              vector[token % EmbeddingService.dimensions] += 1;
            }
          }
          return EmbeddingService.normalized(vector);
        }(),
    ];
  }
}

void main() {
  late Directory tempDir;
  late BookVectorIndex index;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('book_vector_index_test');
    index = BookVectorIndex.forPath(
      FakeEmbeddingService(),
      '${tempDir.path}/vectors.db',
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<String> writeBook(
    String id,
    List<String> pageTexts, {
    Set<int>? presentPages,
  }) async {
    final pages = [
      for (var i = 0; i < pageTexts.length; i++)
        BookPage(
          pageNumber: i + 1,
          chapterIndex: 0,
          chapterTitle: 'Chapter 1',
          layoutType: BookLayoutType.textHeavy,
          needsAiProcessing: false,
          blocks: [ParagraphBlock(text: pageTexts[i])],
        ),
    ];
    final book = ZbfBook(
      manifest: BookManifest(
        id: id,
        title: 'Book $id',
        author: 'Tester',
        sourceFormat: BookSourceFormat.epub,
        pageCount: pages.length,
        chapterCount: 1,
        coverAsset: 'cover.jpg',
        createdAt: DateTime.utc(2026, 1, 1),
        needsAiProcessing: false,
        chapters: [
          ChapterSummary(index: 0, title: 'Chapter 1', pageCount: pages.length),
        ],
      ),
      assets: {
        'cover.jpg': Uint8List.fromList([1]),
      },
    );
    final path = await const ZbfWriter().write(book, '${tempDir.path}/$id.zbf');
    final db = sqlite3.open('$path/pages.db');
    db.execute(
      'CREATE TABLE IF NOT EXISTS pages (page_index INTEGER PRIMARY KEY, chapter_index INTEGER, json TEXT)',
    );
    final stmt = db.prepare(
      'INSERT INTO pages (page_index, chapter_index, json) VALUES (?, ?, ?)',
    );
    for (var i = 0; i < pages.length; i++) {
      if (presentPages != null && !presentPages.contains(i)) continue;
      stmt.execute([i, 0, jsonEncode(pages[i].toJson())]);
    }
    db.close();
    return path;
  }

  void addPage(String path, int pageIndex, String text) {
    final db = sqlite3.open('$path/pages.db');
    final page = BookPage(
      pageNumber: pageIndex + 1,
      chapterIndex: 0,
      chapterTitle: 'Chapter 1',
      layoutType: BookLayoutType.textHeavy,
      needsAiProcessing: false,
      blocks: [ParagraphBlock(text: text)],
    );
    db.execute(
      'INSERT OR REPLACE INTO pages (page_index, chapter_index, json) VALUES (?, ?, ?)',
      [pageIndex, 0, jsonEncode(page.toJson())],
    );
    db.close();
  }

  group('BookChunker', () {
    BookPage page(List<String> paragraphs) => BookPage(
      pageNumber: 1,
      chapterIndex: 0,
      chapterTitle: 'C',
      layoutType: BookLayoutType.textHeavy,
      needsAiProcessing: false,
      blocks: [for (final p in paragraphs) ParagraphBlock(text: p)],
    );

    test('short page becomes a single chunk', () {
      const chunker = BookChunker();
      final chunks = chunker.chunkPage(
        page(['one short paragraph', 'another one']),
        startSeq: 0,
      );
      expect(chunks, hasLength(1));
      expect(chunks.first.pageNumber, 1);
      expect(chunks.first.text, contains('another one'));
    });

    test('long paragraph splits at word boundaries', () {
      const chunker = BookChunker(targetWords: 10, maxWords: 12);
      final words = List.generate(35, (i) => 'word$i').join(' ');
      final chunks = chunker.chunkPage(page([words]), startSeq: 0);
      expect(chunks.length, 4);
      expect(chunks.map((c) => c.seq).toList(), [0, 1, 2, 3]);
      final rejoined = chunks.map((c) => c.text).join(' ');
      expect(rejoined.split(' '), hasLength(35));
    });

    test('accumulates paragraphs up to target', () {
      const chunker = BookChunker(targetWords: 6, maxWords: 8);
      final chunks = chunker.chunkPage(
        page(['alpha beta gamma', 'delta epsilon zeta', 'eta theta']),
        startSeq: 5,
      );
      expect(chunks.first.seq, 5);
      expect(chunks.first.text, contains('alpha'));
      expect(chunks.first.text, contains('zeta'));
    });
  });

  group('BookVectorIndex', () {
    test('embeds a book and ranks semantically similar pages first', () async {
      final path = await writeBook('v1', [
        'lightning network payment channels route sats instantly',
        'gardening tips for tomatoes and cucumbers in spring',
        'bitcoin payment routing uses lightning channels',
      ]);
      await index.ensureEmbedded('v1', path);

      final hits = await index.search(
        'lightning payment channels',
        minScore: 0.1,
      );
      expect(hits, isNotEmpty);
      expect(hits.first.pageNumber, anyOf(1, 3));
      final pages = hits.map((h) => h.pageNumber).toList();
      final gardening = pages.indexOf(2);
      if (gardening != -1) {
        expect(gardening, greaterThan(0));
      }
    });

    test('ensureEmbedded is idempotent', () async {
      final path = await writeBook('v2', ['repeatable embedding content']);
      await index.ensureEmbedded('v2', path);
      await index.ensureEmbedded('v2', path);

      final hits = await index.search('repeatable embedding', minScore: 0.1);
      expect(hits, hasLength(1));
    });

    test('scopes search to one book and removes cleanly', () async {
      final p1 = await writeBook('v3', ['unique aurora borealis passage']);
      final p2 = await writeBook('v4', ['aurora borealis appears here too']);
      await index.ensureEmbedded('v3', p1);
      await index.ensureEmbedded('v4', p2);

      final scoped = await index.search(
        'aurora borealis',
        circleDirId: 'v3',
        minScore: 0.1,
      );
      expect(scoped.every((h) => h.circleDirId == 'v3'), isTrue);

      await index.remove('v3');
      expect(await index.isEmbedded('v3'), isFalse);
      expect(
        await index.search('aurora borealis', circleDirId: 'v3', minScore: 0.1),
        isEmpty,
      );
    });

    test('embeds incrementally as pages land and completes at full coverage', () async {
      final path = await writeBook('v5', [
        'first page about mountain hiking trails',
        'second page about deep sea creatures',
        'third page about ancient roman history',
      ], presentPages: {0});

      await index.ensureEmbedded('v5', path);
      expect(await index.isEmbedded('v5'), isFalse);

      var hits = await index.search(
        'mountain hiking',
        circleDirId: 'v5',
        minScore: 0.1,
      );
      expect(hits.map((h) => h.pageNumber), contains(1));

      addPage(path, 1, 'second page about deep sea creatures');
      addPage(path, 2, 'third page about ancient roman history');
      await index.ensureEmbedded('v5', path);
      expect(await index.isEmbedded('v5'), isTrue);

      hits = await index.search(
        'ancient roman history',
        circleDirId: 'v5',
        minScore: 0.1,
      );
      expect(hits.map((h) => h.pageNumber), contains(3));
    });

    test('does not re-embed pages already processed', () async {
      final path = await writeBook('v6', [
        'alpha content page',
        'beta content page',
      ], presentPages: {0});
      await index.ensureEmbedded('v6', path);
      addPage(path, 1, 'beta content page');
      await index.ensureEmbedded('v6', path);
      await index.ensureEmbedded('v6', path);

      final db = sqlite3.open('${tempDir.path}/vectors.db');
      final counts = db.select(
        'SELECT page_number, COUNT(*) AS n FROM chunks WHERE book_id = ? GROUP BY page_number',
        ['v6'],
      );
      db.close();
      for (final row in counts) {
        expect((row['n'] as num).toInt(), 1);
      }
    });

    test(
      'library-wide search still reaches small unclustered books when a large clustered book exists',
      () async {
        final large = await writeBook('big', [
          for (var i = 0; i < 25; i++)
            'filler page $i about cooking pasta recipes and kitchen equipment',
        ]);
        await index.ensureEmbedded('big', large);

        final small = await writeBook('small', [
          'rare topic quantum entanglement experiments',
        ]);
        await index.ensureEmbedded('small', small);

        final db = sqlite3.open('${tempDir.path}/vectors.db');
        final centroids = db.select(
          'SELECT COUNT(*) AS n FROM centroids WHERE book_id = ?',
          ['big'],
        );
        db.close();
        expect((centroids.first['n'] as num).toInt(), greaterThan(1));

        final hits = await index.search(
          'quantum entanglement experiments',
          minScore: 0.1,
        );
        expect(hits.map((h) => h.circleDirId), contains('small'));
      },
    );
  });

  group('EmbeddingService math', () {
    test('normalized returns unit vector', () {
      final v = Float32List.fromList([3, 4, ...List.filled(382, 0.0)]);
      final n = EmbeddingService.normalized(v);
      expect(EmbeddingService.cosine(n, n), closeTo(1.0, 1e-5));
    });

    test('cosine of orthogonal vectors is zero', () {
      final a = Float32List(384)..[0] = 1;
      final b = Float32List(384)..[1] = 1;
      expect(EmbeddingService.cosine(a, b), 0);
    });
  });
}
