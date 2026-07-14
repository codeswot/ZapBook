import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:zapbook/core/data/search/book_search_index.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/ingestion_orchestrator_cubit.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/features/library/presentation/widgets/continue_reading_card.dart';
import 'package:zapbook/features/library/presentation/widgets/library_book_tile.dart';
import 'package:zapbook/features/library/presentation/widgets/library_processing_tile.dart';
import 'package:zapbook/features/library/presentation/widgets/book_text_search_results.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';

class Shelf extends StatelessWidget {
  const Shelf({
    super.key,
    required this.tasks,
    required this.books,
    this.lastOpenedBook,
    this.allBooks,
    this.searchHits,
    this.searchQuery,
  });

  final Map<String, IngestionTaskState> tasks;
  final List<CircleBook> books;
  final CircleBook? lastOpenedBook;
  final List<CircleBook>? allBooks;
  final List<BookSearchHit>? searchHits;
  final String? searchQuery;

  @override
  Widget build(BuildContext context) {
    final hero = lastOpenedBook ?? (books.isNotEmpty ? books.first : null);
    final tileCount = tasks.length + books.length;

    return CustomScrollView(
      scrollCacheExtent: const ScrollCacheExtent.pixels(600),
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
              if (index < tasks.length) {
                final entry = tasks.entries.elementAt(index);
                return LibraryProcessingTile(
                  circleBookId: entry.key,
                  task: entry.value,
                );
              }
              return CircleBookTile(book: books[index - tasks.length]);
            }, childCount: tileCount),
          ),
        ),
      ],
    );
  }
}
