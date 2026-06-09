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
        isDensitySkippable(
          page(const [], layout: BookLayoutType.illustration),
        ),
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
}
