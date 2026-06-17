import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
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

  Future<String> writeBook(String id, List<String> pageTexts) async {
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
      chapters: [BookChapter(index: 0, title: 'Chapter 1', pages: pages)],
      assets: {
        'cover.jpg': Uint8List.fromList([1]),
      },
    );
    return const ZbfWriter().write(book, '${tempDir.path}/book.zbf');
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
        bookId: 'v3',
        minScore: 0.1,
      );
      expect(scoped.every((h) => h.bookId == 'v3'), isTrue);

      await index.remove('v3');
      expect(await index.isEmbedded('v3'), isFalse);
      expect(
        await index.search('aurora borealis', bookId: 'v3', minScore: 0.1),
        isEmpty,
      );
    });
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
