import 'package:flutter_test/flutter_test.dart';
import 'package:reading_progress/reading_progress.dart';
import 'package:zapbook/features/book_reader/domain/reading_engine.dart';
import 'package:zapbook/zbf/zbf.dart';

ZbfBookHandle _handleFor(BookSourceFormat format, String id) {
  final manifest = BookManifest(
    id: id,
    title: 'Test',
    author: 'Author',
    sourceFormat: format,
    pageCount: 2,
    chapterCount: 2,
    coverAsset: 'cover.png',
    createdAt: DateTime.now(),
    needsAiProcessing: false,
    pageWords: const [1000, 1000],
  );
  return ZbfBookHandle(dirPath: '', manifest: manifest);
}

void main() {
  test('drives to completion and returns BookCompleted on exit', () {
    var now = 0;
    final engine = ReadingEngine(
      deps: ReadingDeps(density: const BookDensity(pageWords: [238, 238])),
      clock: () => now,
    );

    engine.openPage(0);
    for (final t in [10000, 20000, 30000, 40000]) {
      now = t;
      engine.tick();
    }

    now = 40500;
    engine.openPage(1);
    expect(engine.state.completedPages.contains(0), isTrue);

    for (final t in [50500, 60500, 70500, 80500]) {
      now = t;
      engine.tick();
    }

    now = 90000;
    final effects = engine.exitPage(1, ExitDirection.forward);

    expect(engine.state.bookCompleted, isTrue);
    expect(engine.state.completedPages.length, 2);
    expect(effects.whereType<BookCompleted>(), isNotEmpty);
  });

  test('tick accrues engaged time on the open page', () {
    var now = 0;
    final engine = ReadingEngine(
      deps: ReadingDeps(density: const BookDensity(pageWords: [238])),
      clock: () => now,
    );

    engine.openPage(0);
    expect(engine.state.open!.engagedMs, 0);

    now = 5000;
    engine.tick();
    expect(engine.state.open!.engagedMs, greaterThan(0));
  });

  test('epub config completes with less dwell than pdf', () {
    var now = 0;
    final epub = ReadingEngine.forBook(
      _handleFor(BookSourceFormat.epub, 'epub1'),
      clock: () => now,
    );
    epub.openPage(0);
    for (final t in [10000, 20000, 30000, 40000]) {
      now = t;
      epub.tick();
    }
    epub.openPage(1);
    expect(epub.state.completedPages.contains(0), isTrue);

    now = 0;
    final pdf = ReadingEngine.forBook(
      _handleFor(BookSourceFormat.pdf, 'pdf1'),
      clock: () => now,
    );
    pdf.openPage(0);
    for (final t in [10000, 20000, 30000, 40000]) {
      now = t;
      pdf.tick();
    }
    pdf.openPage(1);
    expect(pdf.state.completedPages.contains(0), isFalse);
  });
}
