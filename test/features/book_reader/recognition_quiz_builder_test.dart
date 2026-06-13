import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/core/data/search/book_vector_index.dart';
import 'package:zapbook/core/data/search/embedding_service.dart';
import 'package:zapbook/features/book_reader/data/recognition_quiz_builder.dart';
import 'package:zapbook/zbf/zbf.dart';

class FakeEmbeddingService extends EmbeddingService {
  @override
  Future<Float32List> embedTokens(List<List<int>> pieces) async {
    final vector = Float32List(EmbeddingService.dimensions);
    for (final tokens in pieces) {
      for (final token in tokens) {
        vector[token % EmbeddingService.dimensions] += 1;
      }
    }
    return EmbeddingService.normalized(vector);
  }
}

const _sectionSentences = [
  'The lightning network routes payments through channels between nodes.',
  'Bitcoin uses proof of work to secure its distributed ledger.',
  'Channel capacity limits the size of a single routed payment.',
  'Nodes broadcast gossip messages to share routing information widely.',
  'A payment fails when no route with enough liquidity exists.',
  'Watchtowers help users punish channel partners who try to cheat.',
];

const _distractorSentences = [
  'Tomatoes grow best in warm soil with regular careful watering.',
  'The orchestra tuned their instruments before the evening concert began.',
  'Glaciers carve deep valleys over thousands of years of movement.',
  'Espresso requires finely ground beans and high pressure hot water.',
  'The marathon route wound through the old city center streets.',
  'Migratory birds navigate using the earth magnetic field invisible lines.',
  'Sourdough bread relies on wild yeast and long fermentation times.',
  'The telescope captured faint light from a distant ancient galaxy.',
];

void main() {
  late Directory tempDir;
  late BookVectorIndex vectors;
  late RecognitionQuizBuilder builder;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('recognition_quiz_test');
    vectors = BookVectorIndex.forPath(
      FakeEmbeddingService(),
      '${tempDir.path}/vectors.db',
    );
    builder = RecognitionQuizBuilder(vectors);
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
    return const ZbfWriter().write(book, tempDir);
  }

  Future<void> seedCorpus() async {
    final sec = await writeBook('sec', [_sectionSentences.join(' ')]);
    final other = await writeBook('other', _distractorSentences);
    await vectors.ensureEmbedded('sec', sec);
    await vectors.ensureEmbedded('other', other);
  }

  test('builds presence-framed questions with one odd option', () async {
    await seedCorpus();
    final set = await builder.build(
      'sec',
      0,
      _sectionSentences.join(' '),
      random: Random(7),
    );

    expect(set, isNotNull);
    expect(set!.questions, isNotEmpty);
    final sectionSet = _sectionSentences.toSet();
    final distractorSet = _distractorSentences.toSet();

    for (final q in set.questions) {
      expect(q.options, hasLength(4));
      expect(q.options.toSet(), hasLength(4));
      expect(q.correctIndex, inInclusiveRange(0, 3));
      final answer = q.options[q.correctIndex];
      if (q.text.contains('NOT read')) {
        expect(distractorSet.contains(answer), isTrue);
        final others = [...q.options]..removeAt(q.correctIndex);
        expect(others.every(sectionSet.contains), isTrue);
      } else {
        expect(sectionSet.contains(answer), isTrue);
        final others = [...q.options]..removeAt(q.correctIndex);
        expect(others.every(distractorSet.contains), isTrue);
      }
    }
  });

  test('is deterministic for a fixed seed', () async {
    await seedCorpus();
    final a = await builder.build(
      'sec',
      0,
      _sectionSentences.join(' '),
      random: Random(3),
    );
    final b = await builder.build(
      'sec',
      0,
      _sectionSentences.join(' '),
      random: Random(3),
    );
    expect(a!.questions.first.options, b!.questions.first.options);
    expect(a.questions.first.correctIndex, b.questions.first.correctIndex);
  });

  test('returns null when distractor pool is too small', () async {
    final sec = await writeBook('sec', [_sectionSentences.join(' ')]);
    await vectors.ensureEmbedded('sec', sec);
    final set = await builder.build('sec', 0, _sectionSentences.join(' '));
    expect(set, isNull);
  });

  test('returns null when section has too few sentences', () async {
    await seedCorpus();
    final set = await builder.build('sec', 0, 'Too short.');
    expect(set, isNull);
  });
}
