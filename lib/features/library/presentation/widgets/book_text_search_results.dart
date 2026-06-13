import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/data/search/book_search_index.dart';
import 'package:zapbook/core/router/app_router.dart';
import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/theme/app_theme.dart';

class BookTextSearchResults extends StatelessWidget {
  const BookTextSearchResults({
    super.key,
    required this.hits,
    required this.books,
    required this.query,
  });

  final List<BookSearchHit> hits;
  final List<LibraryBook> books;
  final String query;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final byId = {for (final book in books) book.id: book};
    final visible = hits.where((hit) => byId.containsKey(hit.bookId)).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            'IN BOOKS',
            style: typography.caption.copyWith(
              color: colors.bitcoin,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        for (final hit in visible)
          _SearchHitTile(hit: hit, book: byId[hit.bookId]!, query: query),
      ],
    );
  }
}

class _SearchHitTile extends StatelessWidget {
  const _SearchHitTile({
    required this.hit,
    required this.book,
    required this.query,
  });

  final BookSearchHit hit;
  final LibraryBook book;
  final String query;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return InkWell(
      onTap: () => ZbfViewerRoute(
        zbfPath: book.zbfPath,
        page: hit.pageNumber - 1,
        query: query,
      ).push(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.fileSearch, size: 18, color: colors.slate),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${book.title} · p.${hit.pageNumber}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.bodyS.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text.rich(
                    _highlightedSnippet(hit.snippet, typography, colors),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextSpan _highlightedSnippet(
    String snippet,
    AppTypography typography,
    SemanticColors colors,
  ) {
    final base = typography.caption.copyWith(color: colors.slate);
    final strong = typography.caption.copyWith(
      color: colors.ink,
      fontWeight: FontWeight.w800,
    );
    final parts = snippet.split(BookSearchIndex.highlightStart);
    final spans = <TextSpan>[TextSpan(text: parts.first, style: base)];
    for (final part in parts.skip(1)) {
      final end = part.indexOf(BookSearchIndex.highlightEnd);
      if (end == -1) {
        spans.add(TextSpan(text: part, style: base));
        continue;
      }
      spans.add(TextSpan(text: part.substring(0, end), style: strong));
      spans.add(TextSpan(text: part.substring(end + 1), style: base));
    }
    return TextSpan(children: spans, style: base);
  }
}
