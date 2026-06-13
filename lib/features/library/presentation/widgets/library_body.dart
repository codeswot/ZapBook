import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/features/library/presentation/bloc/book_text_search_cubit.dart';
import 'package:zapbook/features/library/presentation/bloc/ingestion_queue_cubit.dart';
import 'package:zapbook/features/library/presentation/bloc/ingestion_queue_state.dart';
import 'package:zapbook/features/library/presentation/bloc/library_cubit.dart';
import 'package:zapbook/features/library/presentation/widgets/book_text_search_results.dart';
import 'package:zapbook/features/library/presentation/bloc/library_state.dart'
    hide LibraryEmpty;
import 'package:zapbook/features/library/presentation/widgets/library_empty.dart';
import 'package:zapbook/features/library/presentation/widgets/circle_prompt_sheet.dart';
import 'package:zapbook/features/library/presentation/widgets/shelf.dart';
import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/features/library/presentation/widgets/library_shimmer.dart';
import 'package:zapbook/theme/app_theme.dart';

class LibraryBody extends StatelessWidget {
  const LibraryBody({super.key, required this.searchQuery});

  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IngestionQueueCubit, IngestionQueueState>(
      builder: (context, queue) {
        return BlocConsumer<LibraryCubit, LibraryState>(
          listener: (context, library) {
            if (library is LibraryLoaded &&
                library.showCirclePrompt &&
                library.books.isNotEmpty) {
              CirclePromptSheet.show(context, library.books.first);
              context.read<LibraryCubit>().dismissCirclePrompt();
            }
          },
          builder: (context, library) {
            final jobs = queue.visibleJobs;
            final books = switch (library) {
              LibraryLoaded(:final books) => books,
              _ => const <LibraryBook>[],
            };

            if (library is LibraryLoading) {
              return const LibraryShimmer();
            }

            final filteredBooks = books.where((book) {
              final query = searchQuery.trim().toLowerCase();
              if (query.isEmpty) return true;
              return book.title.toLowerCase().contains(query) ||
                  book.author.toLowerCase().contains(query);
            }).toList();

            final textHits = context.watch<BookTextSearchCubit>().state;
            final hasTextHits =
                searchQuery.isNotEmpty &&
                textHits.any((hit) => books.any((b) => b.id == hit.bookId));

            if (filteredBooks.isEmpty &&
                searchQuery.isNotEmpty &&
                !hasTextHits) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 40,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.searchX,
                        size: 48,
                        color: context.colors.slate,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No results found",
                        style: context.typography.h3.copyWith(
                          color: context.colors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "No books matching \"$searchQuery\" were found on your shelf.",
                        textAlign: TextAlign.center,
                        style: context.typography.bodyS.copyWith(
                          color: context.colors.slate,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (filteredBooks.isEmpty && jobs.isEmpty && !hasTextHits) {
              return const SingleChildScrollView(child: LibraryEmpty());
            }

            if (!hasTextHits) {
              return Shelf(jobs: jobs, books: filteredBooks);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BookTextSearchResults(hits: textHits, books: books),
                Expanded(
                  child: Shelf(jobs: jobs, books: filteredBooks),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
