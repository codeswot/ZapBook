import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/router/app_router.dart';
import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/features/library/presentation/bloc/library_cubit.dart';
import 'package:zapbook/features/library/presentation/bloc/library_state.dart';
import 'package:zapbook/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:zapbook/features/home/presentation/widgets/home_header.dart';
import 'package:zapbook/features/home/presentation/widgets/home_continue_reading_card.dart';
import 'package:zapbook/features/home/presentation/widgets/home_stats_row.dart';
import 'package:zapbook/features/home/presentation/widgets/home_up_next_row.dart';
import 'package:zapbook/theme/app_theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileCubit>(
      create: (_) => getIt<ProfileCubit>(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  LibraryBook? _lastOpened(List<LibraryBook> books) {
    if (books.isEmpty) return null;
    LibraryBook? opened;
    for (final book in books) {
      if (book.lastOpenedAt == null) continue;
      if (opened == null || book.lastOpenedAt!.isAfter(opened.lastOpenedAt!)) {
        opened = book;
      }
    }
    return opened ?? books.first;
  }

  void _onBookTap(BuildContext context, LibraryBook book) {
    if (book.isShared) {
      CircleDetailRoute(bookId: book.id).push(context);
    } else {
      context.read<LibraryCubit>().markOpened(book.id);
      ZbfViewerRoute(zbfPath: book.zbfPath).push(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Scaffold(
      backgroundColor: colors.paper,
      body: SafeArea(
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, profileState) {
            final profile = profileState is ProfileLoaded
                ? profileState.profile
                : null;
            final streakCount = profile?.dayStreak ?? 0;

            return Column(
              children: [
                HomeHeader(streakCount: streakCount),
                Expanded(
                  child: BlocBuilder<LibraryCubit, LibraryState>(
                    builder: (context, libraryState) {
                      final books = libraryState is LibraryLoaded
                          ? libraryState.books
                          : const <LibraryBook>[];
                      if (books.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.bookOpen,
                                  size: 48,
                                  color: colors.slate,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Your shelf is empty',
                                  style: typography.h3.copyWith(
                                    color: colors.ink,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Go to the Library tab to add your first book.',
                                  textAlign: TextAlign.center,
                                  style: typography.bodyS.copyWith(
                                    color: colors.slate,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final currentBook = _lastOpened(books);
                      final otherBooks = books
                          .where((b) => b.id != currentBook?.id)
                          .toList();

                      return ListView(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        children: [
                          if (currentBook != null) ...[
                            HomeContinueReadingCard(
                              book: currentBook,
                              onTap: () => _onBookTap(context, currentBook),
                            ),
                            const SizedBox(height: 20),
                          ],
                          if (profile != null) ...[
                            HomeStatsRow(profile: profile),
                            const SizedBox(height: 24),
                          ],
                          if (otherBooks.isNotEmpty) ...[
                            HomeUpNextRow(
                              books: otherBooks,
                              onBookTap: _onBookTap,
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
