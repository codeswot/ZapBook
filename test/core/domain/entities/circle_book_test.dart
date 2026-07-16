import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/zbf/enums/book_source_format.dart';

void main() {
  group('CircleBook', () {
    final now = DateTime.now();

    final book = CircleBook(
      id: '1',
      nostrGroudId: 'n1',
      circleDirId: 'd1',
      title: 'Title',
      author: 'Author',
      sourceFormat: BookSourceFormat.epub,
      pageCount: 10,
      chapterCount: 2,
      zbfPath: 'path/to/zbf',
      needsAiProcessing: false,
      zbfVersion: '1.0',
      createdAt: now,
      genres: [],
      addedAt: now,
      memberCount: 1,
    );

    test('props contains all relevant fields', () {
      expect(book.props, [
        '1',
        'Title',
        'Author',
        <String>[],
        BookSourceFormat.epub,
        10,
        2,
        'path/to/zbf',
        null,
        false,
        '1.0',
        now,
        now,
        null,
        null,
        1,
        const [],
        false,
      ]);
    });

    test('copyWith updates specified fields', () {
      final updated = book.copyWith(
        title: 'New Title',
        memberCount: 5,
        removedFromCircle: true,
      );

      expect(updated.title, 'New Title');
      expect(updated.memberCount, 5);
      expect(updated.removedFromCircle, isTrue);

      // Unchanged
      expect(updated.id, '1');
      expect(updated.author, 'Author');
    });

    test('isShared returns true when memberCount > 1', () {
      expect(book.isShared, isFalse);

      final sharedBook = book.copyWith(memberCount: 2);
      expect(sharedBook.isShared, isTrue);
    });

    test('isDownloaded returns true when manifest exists', () async {
      final dir = Directory.systemTemp.createTempSync('zbf_test');
      try {
        // copyWith doesn't allow changing zbfPath directly.
        // Wait, zbfPath is final, copyWith doesn't have zbfPath.
        final b2 = CircleBook(
          id: '1',
          nostrGroudId: 'n1',
          circleDirId: 'd1',
          title: 'Title',
          author: 'Author',
          sourceFormat: BookSourceFormat.epub,
          pageCount: 10,
          chapterCount: 2,
          zbfPath: dir.path,
          needsAiProcessing: false,
          zbfVersion: '1.0',
          createdAt: now,
          addedAt: now,
        );

        expect(b2.isDownloaded, isFalse);

        File('${dir.path}/manifest.json').createSync();
        expect(b2.isDownloaded, isTrue);
      } finally {
        dir.deleteSync(recursive: true);
      }
    });
  });
}
