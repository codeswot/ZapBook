import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/core/presentation/bloc/book_download/book_download_cubit.dart';
import 'package:zapbook/core/presentation/bloc/book_download/book_download_state.dart';

import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/core/presentation/widgets/app_button.dart';
import 'package:zapbook/core/presentation/router/app_router.dart';
import 'package:zapbook/core/presentation/widgets/bouncing_interactive_widget.dart';
import 'package:zapbook/features/circles/presentation/bloc/circle_detail_cubit.dart';
import 'package:zapbook/features/circles/presentation/bloc/circle_detail_state.dart';
import 'package:zapbook/features/circles/presentation/bloc/circle_members_state.dart'
    show MemberEntry;
import 'package:zapbook/features/circles/presentation/widgets/circle_detail/circle_detail_top_bar.dart';
import 'package:zapbook/features/circles/presentation/widgets/circle_detail/circle_my_progress_card.dart';
import 'package:zapbook/features/circles/presentation/widgets/circle_detail/circle_reader_tile.dart';
import 'package:zapbook/features/circles/presentation/widgets/circle_detail/circle_removed_banner.dart';
import 'package:zapbook/features/circles/presentation/widgets/circle_settings_sheet.dart';
import 'package:zapbook/features/circles/presentation/widgets/reader_actions_sheet.dart';
import 'package:zapbook/features/circles/presentation/widgets/circle_detail/circle_leaderboard_sheet.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';

class CircleLoadedView extends StatelessWidget {
  const CircleLoadedView({
    super.key,
    required this.circleBookId,
    required this.state,
  });

  final String circleBookId;
  final CircleDetailLoaded state;

  CircleBook get book => state.book;

  void _openBook(BuildContext context) {
    if (!book.isDownloaded) {
      context.read<BookDownloadCubit>().downloadBook(book);
      context.read<CircleDetailCubit>().open(circleBookId);
    } else {
      context.read<CircleDetailCubit>().open(circleBookId);
    }

    ZbfViewerRoute(
      zbfPath: book.zbfPath,
      bookTitle: book.title,
      coverPath: book.coverPath,
      circleDirId: book.circleDirId,
      groupId: book.id,
    ).push(context);
  }

  void _openSettings(BuildContext context) {
    CircleSettingsSheet.show(
      context,
      cubit: context.read<CircleDetailCubit>(),
      book: book,
      isAdmin: state.isAdmin,
    );
  }

  void _readerActions(BuildContext context, MemberEntry entry) {
    ReaderActionsSheet.show(
      context,
      cubit: context.read<CircleDetailCubit>(),
      entry: entry,
      circleBookId: circleBookId,
      bookTitle: book.title,
      canRemove: state.isAdmin,
    );
  }

  void _showLeaderboard(BuildContext context) {
    CircleLeaderboardSheet.show(
      context,
      cubit: context.read<CircleDetailCubit>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    final sortedMembers = List<MemberEntry>.from(state.members)
      ..sort((a, b) {
        if (a.isSelf && !b.isSelf) return 1;
        if (!a.isSelf && b.isSelf) return -1;
        return state.memberProgress.compareEntries(a, b);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CircleDetailTopBar(
          readersCount: state.members.length,
          circleBookId: circleBookId,
          bookTitle: book.title,
          onSettings: book.removedFromCircle
              ? null
              : () => _openSettings(context),
        ),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (book.removedFromCircle) ...[
                      const CircleRemovedBanner(),
                      const SizedBox(height: 14),
                    ],
                    CircleMyProgressCard(
                      book: book,
                      myNpub: state.myNpub,
                      myProgressFraction:
                          state.memberProgress[state.myNpub]?.fraction ?? 0,
                      myPage:
                          state.memberProgress[state.myNpub]?.currentPage ??
                          state.myPage,
                      satsEarned: state.satsEarned,
                    ),
                    const SizedBox(height: 14),
                    BlocBuilder<BookDownloadCubit, BookDownloadState>(
                      builder: (context, state) {
                        return AppButton(
                          label: book.isDownloaded
                              ? 'Open book'
                              : 'Download and open book',
                          icon: book.isDownloaded
                              ? LucideIcons.bookOpen
                              : LucideIcons.cloudDownload,
                          fullWidth: true,
                          onTap: () => _openBook(context),
                        );
                      },
                    ),
                    const SizedBox(height: 26),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Readers',
                          style: typography.h3.copyWith(color: colors.ink),
                        ),
                        const Spacer(),
                        BouncingInteractiveWidget(
                          onTap: () => _showLeaderboard(context),

                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colors.paper3,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: colors.hairline),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.medal,
                                  size: 16,
                                  color: colors.bitcoin,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Leaderboard',
                                  style: typography.caption.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final entry = sortedMembers[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CircleReaderTile(
                        entry: entry,
                        isOwner: state.isMemberAdmin(entry.npub),
                        isYou: entry.isSelf,
                        pageCount: book.pageCount,
                        bookTitle: book.title,
                        circleBookId: book.id,
                        memberProgress: state.memberProgress,
                        onLongPress: entry.isSelf
                            ? null
                            : () => _readerActions(context, entry),
                      ),
                    );
                  }, childCount: sortedMembers.length),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
