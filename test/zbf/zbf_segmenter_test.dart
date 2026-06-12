import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/zbf/zbf.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('zbf_segmenter_test');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  ZbfBook buildBook({int pageCount = 45}) {
    final pagesPerChapter = 25;
    final pages = [
      for (var i = 0; i < pageCount; i++)
        BookPage(
          pageNumber: i + 1,
          chapterIndex: i ~/ pagesPerChapter,
          chapterTitle: 'Chapter ${i ~/ pagesPerChapter + 1}',
          layoutType: i == 0
              ? BookLayoutType.illustration
              : BookLayoutType.textHeavy,
          needsAiProcessing: false,
          blocks: [
            ParagraphBlock(text: 'Page ${i + 1} body'),
            if (i == 0) const ImageBlock(assetRef: 'img_001.png'),
          ],
        ),
    ];
    final byChapter = <int, List<BookPage>>{};
    for (final page in pages) {
      (byChapter[page.chapterIndex] ??= []).add(page);
    }
    final chapters = [
      for (final entry in byChapter.entries)
        BookChapter(
          index: entry.key,
          title: entry.value.first.chapterTitle,
          pages: entry.value,
        ),
    ];
    final manifest = BookManifest(
      id: 'book-1',
      title: 'Test Book',
      author: 'Tester',
      sourceFormat: BookSourceFormat.epub,
      pageCount: pageCount,
      chapterCount: chapters.length,
      coverAsset: 'cover.jpg',
      createdAt: DateTime.utc(2026, 1, 1),
      needsAiProcessing: false,
      chapters: [
        for (final chapter in chapters)
          ChapterSummary(
            index: chapter.index,
            title: chapter.title,
            pageCount: chapter.pages.length,
          ),
      ],
    );
    return ZbfBook(
      manifest: manifest,
      chapters: chapters,
      assets: {
        'img_001.png': Uint8List.fromList([1, 2, 3, 4]),
        'cover.jpg': Uint8List.fromList([9, 9, 9]),
      },
    );
  }

  test('segment splits book into page-bounded blobs', () async {
    const segmenter = ZbfSegmenter();
    final path = await const ZbfWriter().write(buildBook(), tempDir);
    final handle = await const ZbfReader().open(path);

    final blobs = segmenter.segment(handle).toList();

    expect(blobs.length, ZbfSegmenter.segmentCountFor(45));
    expect(blobs.first.pageStart, 0);
    expect(blobs.first.pageEnd, 19);
    expect(blobs.last.pageEnd, 44);
  });

  test('reassembleToFile rebuilds full book from segment stream', () async {
    const segmenter = ZbfSegmenter();
    final book = buildBook();
    final path = await const ZbfWriter().write(book, tempDir);
    final handle = await const ZbfReader().open(path);

    final blobs = segmenter.segment(handle).toList();
    final outputPath = '${tempDir.path}/rebuilt.zbf';
    await segmenter.reassembleToFile(
      Stream.fromIterable([for (final blob in blobs) blob.bytes]),
      outputPath,
      coverBytes: book.assets['cover.jpg'],
      sourceBytes: Uint8List.fromList([7, 7]),
    );

    final rebuilt = await const ZbfReader().open(outputPath);
    expect(rebuilt.manifest.id, book.manifest.id);
    expect(rebuilt.manifest.pageCount, 45);
    expect(rebuilt.pageAt(0).pageNumber, 1);
    expect(rebuilt.pageAt(44).pageNumber, 45);
    expect(rebuilt.pageAt(30).chapterTitle, 'Chapter 2');
    expect(rebuilt.asset('img_001.png'), [1, 2, 3, 4]);
    expect(rebuilt.asset('cover.jpg'), [9, 9, 9]);
    expect(rebuilt.sourceDocument(), [7, 7]);
    expect(File('$outputPath.part').existsSync(), isFalse);
  });

  test('reassembleToFile cleans up partial file on failure', () async {
    const segmenter = ZbfSegmenter();
    final outputPath = '${tempDir.path}/broken.zbf';

    await expectLater(
      segmenter.reassembleToFile(
        Stream<Uint8List>.error(StateError('download failed')),
        outputPath,
      ),
      throwsStateError,
    );

    expect(File(outputPath).existsSync(), isFalse);
    expect(File('$outputPath.part').existsSync(), isFalse);
  });
}
