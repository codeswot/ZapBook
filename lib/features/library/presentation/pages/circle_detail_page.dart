import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/router/app_router.dart';
import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/features/library/presentation/bloc/circle_detail_cubit.dart';
import 'package:zapbook/features/library/presentation/bloc/circle_detail_state.dart';
import 'package:zapbook/features/library/presentation/bloc/circle_members_state.dart'
    show MemberEntry;
import 'package:zapbook/features/library/presentation/widgets/circle_settings_sheet.dart';
import 'package:zapbook/features/library/presentation/widgets/reader_actions_sheet.dart';
import 'package:zapbook/features/library/presentation/widgets/circle_detail/circle_detail_top_bar.dart';
import 'package:zapbook/features/library/presentation/widgets/circle_detail/circle_detail_shimmer.dart';
import 'package:zapbook/features/library/presentation/widgets/circle_detail/circle_my_progress_card.dart';
import 'package:zapbook/features/library/presentation/widgets/circle_detail/circle_reader_tile.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_button.dart';

class CircleDetailPage extends StatelessWidget {
  const CircleDetailPage({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CircleDetailCubit>()..load(bookId),
      child: _CircleDetailView(bookId: bookId),
    );
  }
}

class _CircleDetailView extends StatelessWidget {
  const _CircleDetailView({required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.paper,
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<CircleDetailCubit, CircleDetailState>(
          listener: (context, state) {
            if (state is CircleDetailClosed) context.pop();
          },
          builder: (context, state) {
            return switch (state) {
              CircleDetailLoaded() => _Loaded(bookId: bookId, state: state),
              CircleDetailError(:final message) => _Error(message: message),
              _ => CircleDetailShimmer(bookId: bookId),
            };
          },
        ),
      ),
    );
  }
}

class _RemovedBanner extends StatelessWidget {
  const _RemovedBanner();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.coralTint,
        borderRadius: AppRadii.br12,
        border: Border.all(color: colors.coral.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.userMinus, size: 20, color: colors.coral),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You've been removed from this circle",
                  style: typography.label.copyWith(color: colors.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  'You can still read your downloaded copy, but progress no '
                  'longer syncs with the group.',
                  style: typography.bodyS.copyWith(color: colors.slate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CircleDetailTopBar(
          readersCount: 0,
          bookId: '',
          bookTitle: 'Circle',
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: context.typography.body.copyWith(
                  color: context.colors.slate,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.bookId, required this.state});

  final String bookId;
  final CircleDetailLoaded state;

  LibraryBook get book => state.book;

  ImageProvider? get _coverImage {
    final path = book.coverPath;
    return path != null ? FileImage(File(path)) : null;
  }

  void _openBook(BuildContext context) {
    context.read<CircleDetailCubit>().open(bookId);
    ZbfViewerRoute(zbfPath: book.zbfPath).push(context);
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
      bookId: bookId,
      bookTitle: book.title,
      canRemove: state.isAdmin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CircleDetailTopBar(
          readersCount: state.members.length,
          bookId: bookId,
          bookTitle: book.title,
          onSettings: book.removedFromCircle
              ? null
              : () => _openSettings(context),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
            children: [
              const SizedBox(height: 18),
              if (book.removedFromCircle) ...[
                const _RemovedBanner(),
                const SizedBox(height: 14),
              ],
              CircleMyProgressCard(
                book: book,
                cover: _coverImage,
                myNpub: state.myNpub,
                myProgressFraction:
                    state.memberProgress[state.myNpub]?.fraction ?? 0,
                myPage:
                    state.memberProgress[state.myNpub]?.currentPage ??
                    state.myPage,
                satsEarned: state.satsEarned,
              ),
              const SizedBox(height: 14),
              AppButton(
                label: 'Open book',
                icon: LucideIcons.bookOpen,
                fullWidth: true,
                onTap: () => _openBook(context),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Text(
                    'Readers',
                    style: typography.h3.copyWith(color: colors.ink),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final entry in state.members) ...[
                CircleReaderTile(
                  entry: entry,
                  isOwner: state.isMemberAdmin(entry.npub),
                  isYou: entry.isSelf,
                  pageCount: book.pageCount,
                  bookTitle: book.title,
                  bookId: book.id,
                  memberProgress: state.memberProgress,
                  onLongPress: entry.isSelf
                      ? null
                      : () => _readerActions(context, entry),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
