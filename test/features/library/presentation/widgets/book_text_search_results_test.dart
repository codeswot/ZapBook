import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zapbook/core/domain/entities/book_search_hit.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/features/library/presentation/widgets/book_text_search_results.dart';
import 'package:zapbook/zbf/enums/book_source_format.dart';

CircleBook _book({required String id, required String circleDirId}) =>
    CircleBook(
      id: id,
      nostrGroudId: 'nostr_$id',
      circleDirId: circleDirId,
      title: 'Web Handbook',
      author: 'Author',
      sourceFormat: BookSourceFormat.epub,
      pageCount: 10,
      chapterCount: 1,
      zbfPath: '/tmp/none',
      needsAiProcessing: false,
      zbfVersion: '1',
      createdAt: DateTime.utc(2026),
      addedAt: DateTime.utc(2026),
    );

void main() {
  testWidgets('matches hits by circleDirId even when group id differs', (
    tester,
  ) async {
    final book = _book(id: 'group-abc', circleDirId: 'dir-123');
    const hit = BookSearchHit(
      circleDirId: 'dir-123',
      pageNumber: 4,
      chapterTitle: 'C1',
      snippet: 'about the ‹web› of things',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: Scaffold(
          body: BookTextSearchResults(
            hits: const [hit],
            books: [book],
            query: 'web',
          ),
        ),
      ),
    );

    expect(find.text('IN BOOKS'), findsOneWidget);
    expect(find.textContaining('Web Handbook'), findsOneWidget);
    expect(find.textContaining('p.4'), findsOneWidget);
  });

  testWidgets('renders nothing when hit belongs to no shelf book', (
    tester,
  ) async {
    final book = _book(id: 'group-abc', circleDirId: 'dir-123');
    const hit = BookSearchHit(
      circleDirId: 'other-book',
      pageNumber: 1,
      chapterTitle: 'C1',
      snippet: 'snippet',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: Scaffold(
          body: BookTextSearchResults(
            hits: const [hit],
            books: [book],
            query: 'web',
          ),
        ),
      ),
    );

    expect(find.text('IN BOOKS'), findsNothing);
  });
}
