import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/router/app_router.dart';
import 'package:zapbook/features/home/domain/entities/home_dashboard.dart';
import 'package:zapbook/features/home/presentation/bloc/home_cubit.dart';
import 'package:zapbook/features/home/presentation/bloc/home_state.dart';
import 'package:zapbook/features/home/presentation/widgets/home_header.dart';
import 'package:zapbook/features/home/presentation/widgets/home_continue_reading_card.dart';
import 'package:zapbook/features/home/presentation/widgets/home_stats_row.dart';
import 'package:zapbook/features/home/presentation/widgets/home_up_next_row.dart';
import 'package:zapbook/features/home/presentation/widgets/home_shimmer.dart';
import 'package:zapbook/theme/app_theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeCubit>(
      create: (_) => getIt<HomeCubit>(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  HomeDashboardBook? _lastOpened(List<HomeDashboardBook> books) {
    if (books.isEmpty) return null;
    HomeDashboardBook? opened;
    for (final book in books) {
      if (book.lastOpenedAt == null) continue;
      if (opened == null || book.lastOpenedAt!.isAfter(opened.lastOpenedAt!)) {
        opened = book;
      }
    }
    return opened ?? books.first;
  }

  void _onCardTap(BuildContext context, HomeDashboardBook book) {
    if (book.isShared) {
      CircleDetailRoute(bookId: book.id).push(context);
    } else {
      context.read<HomeCubit>().touchBookOpened(book.id);
      ZbfViewerRoute(zbfPath: book.zbfPath).push(context);
    }
  }

  void _onBookOpen(BuildContext context, HomeDashboardBook book) {
    context.read<HomeCubit>().touchBookOpened(book.id);
    ZbfViewerRoute(zbfPath: book.zbfPath).push(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Scaffold(
      backgroundColor: colors.paper,
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state is HomeLoading) {
              return Column(
                children: [
                  const HomeHeader(streakCount: 0),
                  const Expanded(child: HomeShimmer()),
                ],
              );
            }

            if (state is HomeError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    state.message,
                    style: typography.bodyS.copyWith(color: colors.coral),
                  ),
                ),
              );
            }

            final dashboard = (state as HomeLoaded).dashboard;
            final books = dashboard.books;
            final stats = dashboard.stats;
            final streakCount = stats.dayStreak;

            return Column(
              children: [
                HomeHeader(streakCount: streakCount),
                Expanded(
                  child: books.isEmpty
                      ? Center(
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
                                const SizedBox(height: 24),
                                FilledButton.icon(
                                  onPressed: () =>
                                      const LibraryRoute().go(context),
                                  icon: const Icon(LucideIcons.plus),
                                  label: const Text('Go to Library'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: colors.bitcoin,
                                    foregroundColor: colors.bitcoinDark,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          children: [
                            (() {
                              final currentBook = _lastOpened(books);
                              if (currentBook != null) {
                                return HomeContinueReadingCard(
                                  book: currentBook,
                                  onTap: () => _onCardTap(context, currentBook),
                                  onBookOpen: () =>
                                      _onBookOpen(context, currentBook),
                                );
                              }
                              return const SizedBox.shrink();
                            })(),
                            const SizedBox(height: 20),
                            HomeStatsRow(stats: stats),
                            const SizedBox(height: 24),
                            (() {
                              final currentBook = _lastOpened(books);
                              final otherBooks = books
                                  .where((b) => b.id != currentBook?.id)
                                  .toList();
                              if (otherBooks.isNotEmpty) {
                                return HomeUpNextRow(
                                  books: otherBooks,
                                  onBookTap: _onCardTap,
                                );
                              }
                              return const SizedBox.shrink();
                            })(),
                          ],
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
