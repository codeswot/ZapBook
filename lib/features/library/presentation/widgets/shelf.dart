import 'package:flutter/material.dart';
import 'package:zapbook/core/data/search/book_search_index.dart';
import 'package:zapbook/features/library/domain/entities/ingestion_job.dart';
import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/features/library/presentation/widgets/continue_reading_card.dart';
import 'package:zapbook/features/library/presentation/widgets/library_book_tile.dart';
import 'package:zapbook/features/library/presentation/widgets/library_processing_tile.dart';
import 'package:zapbook/features/library/presentation/widgets/book_text_search_results.dart';
import 'package:zapbook/theme/app_theme.dart';

class Shelf extends StatelessWidget {
  const Shelf({
    super.key,
    required this.jobs,
    required this.books,
    this.allBooks,
    this.searchHits,
    this.searchQuery,
  });

  final List<IngestionJob> jobs;
  final List<LibraryBook> books;
  final List<LibraryBook>? allBooks;
  final List<BookSearchHit>? searchHits;
  final String? searchQuery;

  LibraryBook? _lastOpened(List<LibraryBook> books) {
    if (books.isEmpty) {
      return null;
    }
    LibraryBook? opened;
    for (final book in books) {
      if (book.lastOpenedAt == null) {
        continue;
      }
      if (opened == null || book.lastOpenedAt!.isAfter(opened.lastOpenedAt!)) {
        opened = book;
      }
    }
    return opened ?? books.first;
  }

  @override
  Widget build(BuildContext context) {
    final hero = _lastOpened(books);
    final tileCount = jobs.length + books.length;

    return CustomScrollView(
      slivers: [
        if (searchHits != null &&
            searchQuery != null &&
            searchQuery!.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: BookTextSearchResults(
              hits: searchHits!,
              books: allBooks ?? books,
              query: searchQuery!,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: Divider(
                color: context.colors.hairline,
                height: 1,
                indent: 24,
                endIndent: 24,
              ),
            ),
          ),
        ],
        if (hero != null)
          SliverToBoxAdapter(child: ContinueReadingCard(book: hero)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
          sliver: SliverToBoxAdapter(
            child: Text(
              'All Books',
              style: context.typography.eyebrow.copyWith(
                color: context.colors.slate,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 18,
              crossAxisSpacing: 14,
              childAspectRatio: 0.727,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index < jobs.length) {
                return LibraryProcessingTile(job: jobs[index]);
              }
              return LibraryBookTile(book: books[index - jobs.length]);
            }, childCount: tileCount),
          ),
        ),
      ],
    );
  }
}
