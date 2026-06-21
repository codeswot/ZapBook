import 'package:flutter_test/flutter_test.dart';

import 'package:reading_progress/reading_progress.dart';
import 'package:zapbook/features/book_reader/data/book_density_mapper.dart';
import 'package:zapbook/zbf/zbf.dart';

BookPage page(
  List<BookBlock> blocks, {
  BookLayoutType layout = BookLayoutType.textHeavy,
}) => BookPage(
  pageNumber: 1,
  chapterIndex: 0,
  chapterTitle: '',
  layoutType: layout,
  needsAiProcessing: false,
  blocks: blocks,
);

void main() {
  group('countWords', () {
    test('counts whitespace-separated tokens', () {
      expect(countWords('the quick  brown\nfox'), 4);
      expect(countWords('   '), 0);
      expect(countWords(''), 0);
    });
  });

  group('pageWordCount', () {
    test('sums text-bearing blocks, ignores images/dividers', () {
      final p = page([
        const HeadingBlock(level: 1, text: 'Chapter One'),
        const ParagraphBlock(text: 'two words'),
        const ImageBlock(assetRef: 'a.png'),
        const DividerBlock(),
      ]);
      expect(pageWordCount(p), 4);
    });
  });

  group('isDensitySkippable', () {
    test('blank page is skippable', () {
      expect(isDensitySkippable(page(const [])), isTrue);
    });

    test('table of contents is skippable', () {
      final toc = page(const [
        ParagraphBlock(text: 'Chapter 1 .......... 3'),
        ParagraphBlock(text: 'Chapter 2 .......... 21'),
        ParagraphBlock(text: 'Chapter 3 .......... 48'),
      ]);
      expect(isDensitySkippable(toc), isTrue);
    });

    test('illustration and processing pages are not skippable', () {
      expect(
        isDensitySkippable(page(const [], layout: BookLayoutType.illustration)),
        isFalse,
      );
      expect(
        isDensitySkippable(page(const [], layout: BookLayoutType.processing)),
        isFalse,
      );
    });

    test('normal text page is not skippable', () {
      expect(
        isDensitySkippable(page(const [ParagraphBlock(text: 'real content')])),
        isFalse,
      );
    });
  });

  group('genreFromLabel', () {
    test('maps labels to Genre', () {
      expect(genreFromLabel('Science Fiction'), Genre.fiction);
      expect(genreFromLabel('Non-Fiction'), Genre.nonFiction);
      expect(genreFromLabel('nonfiction'), Genre.nonFiction);
      expect(genreFromLabel('Biography'), Genre.unknown);
      expect(genreFromLabel(null), Genre.unknown);
    });
  });

  group('bookDensityFromPages', () {
    test('builds word counts, skippable set, and genre', () {
      final pages = [
        page(const [ParagraphBlock(text: 'one two three')]),
        page(const []),
        page(const [ParagraphBlock(text: 'four five')]),
      ];
      final density = bookDensityFromPages(pages, genre: 'Fantasy Fiction');

      expect(density.pageWords, [3, 0, 2]);
      expect(density.totalWords, 5);
      expect(density.skippablePages, {1});
      expect(density.contentPages, [0, 2]);
      expect(density.genre, Genre.fiction);
    });
  });

  group('extractMilestoneText', () {
    test('extracts exact range of words across multiple pages', () {
      final manifest = BookManifest(
        id: 'test_book',
        title: 'Test Title',
        author: 'Author',
        sourceFormat: BookSourceFormat.epub,
        pageCount: 3,
        chapterCount: 1,
        createdAt: DateTime.now(),
        needsAiProcessing: false,
        pageWords: const [6, 6, 6],
        coverAsset: 'cover.png',
      );
      final handle = ZbfBookHandle(dirPath: '', manifest: manifest);
      handle.updatePage(
        0,
        page([const ParagraphBlock(text: 'one two three four five six')]),
      );
      handle.updatePage(
        1,
        page([
          const ParagraphBlock(text: 'seven eight nine ten eleven twelve'),
        ]),
      );
      handle.updatePage(
        2,
        page([
          const ParagraphBlock(
            text: 'thirteen fourteen fifteen sixteen seventeen eighteen',
          ),
        ]),
      );

      final density = BookDensity(pageWords: const [6, 6, 6]);

      // Milestone 0 (words 0 to 5)
      expect(
        extractMilestoneText(handle, density, 0, wordsPerMilestone: 5),
        'one two three four five',
      );

      // Milestone 1 (words 5 to 10)
      // Words:
      // Page 0: [one, two, three, four, five, six] -> index 5 is 'six' (p.startWord=0, index relative to page is 5)
      // Page 1: [seven, eight, nine, ten, eleven, twelve] -> indices 6 to 9 are 'seven eight nine ten' (p.startWord=6, indices 0 to 3)
      expect(
        extractMilestoneText(handle, density, 1, wordsPerMilestone: 5),
        'six seven eight nine ten',
      );

      // Milestone 2 (words 10 to 15)
      // Words:
      // Page 1: [eleven, twelve] -> index 10 is 'eleven' (p.startWord=6, index relative to page is 4)
      // Page 2: [thirteen, fourteen, fifteen] -> index 12 to 14 (p.startWord=12, indices 0 to 2)
      expect(
        extractMilestoneText(handle, density, 2, wordsPerMilestone: 5),
        'eleven twelve thirteen fourteen fifteen',
      );
    });

    test(
      'respects sentence end trimming when a sentence ends within the extracted region',
      () {
        final manifest = BookManifest(
          id: 'test_book_sentences',
          title: 'Test Title',
          author: 'Author',
          sourceFormat: BookSourceFormat.epub,
          pageCount: 2,
          chapterCount: 1,
          createdAt: DateTime.now(),
          needsAiProcessing: false,
          pageWords: const [6, 6],
          coverAsset: 'cover.png',
        );
        final handle = ZbfBookHandle(dirPath: '', manifest: manifest);
        handle.updatePage(
          0,
          page([const ParagraphBlock(text: 'one. two three. four five six')]),
        );
        handle.updatePage(
          1,
          page([
            const ParagraphBlock(text: 'seven eight. nine ten eleven twelve'),
          ]),
        );

        final density = BookDensity(pageWords: const [6, 6]);

        // Milestone 0 (words 0 to 10)
        // Words: 'one. two three. four five six seven eight. nine'
        // There are sentence endings: 'one. ', 'three. ', 'eight. '
        // The last sentence ending is 'eight. ', so it should trim at the end of 'eight.'
        expect(
          extractMilestoneText(handle, density, 0, wordsPerMilestone: 10),
          'one. two three. four five six seven eight.',
        );
      },
    );
  });
}
