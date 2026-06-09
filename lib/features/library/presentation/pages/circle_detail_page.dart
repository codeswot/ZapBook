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
import 'package:zapbook/core/domain/milestone_payload.dart';
import 'package:zapbook/features/library/presentation/widgets/circle_confirm_sheet.dart';
import 'package:zapbook/features/library/presentation/widgets/circle_settings_sheet.dart';
import 'package:zapbook/features/library/presentation/widgets/reader_actions_sheet.dart';
import 'package:zapbook/features/library/presentation/widgets/circle_detail/circle_detail_bottom_bar.dart';
import 'package:zapbook/features/library/presentation/widgets/circle_detail/circle_detail_top_bar.dart';
import 'package:zapbook/features/library/presentation/widgets/circle_detail/circle_my_progress_card.dart';
import 'package:zapbook/features/library/presentation/widgets/circle_detail/circle_placeholders.dart';
import 'package:zapbook/features/library/presentation/widgets/circle_detail/circle_reader_tile.dart';
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
              _ => const Center(child: CircularProgressIndicator()),
            };
          },
        ),
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

  List<MemberEntry> get _sortedReaders {
    final readers = [...state.members];
    readers.sort(
      (a, b) => circleProgressFraction(
        b.npub,
      ).compareTo(circleProgressFraction(a.npub)),
    );
    return readers;
  }

  void _openBook(BuildContext context) {
    context.read<CircleDetailCubit>().open(bookId);
    ZbfViewerRoute(zbfPath: book.zbfPath).push(context);
  }

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<CircleDetailCubit>();
    final confirmed = await CircleConfirmSheet.show(
      context,
      title: 'Delete this circle?',
      message:
          'Everyone except you will be removed from “${book.title}”. '
          'The book stays in your library as a private copy.',
      action: 'Delete circle',
    );
    if (confirmed) await cubit.dissolve(bookId);
  }

  Future<void> _leave(BuildContext context) async {
    final cubit = context.read<CircleDetailCubit>();
    final confirmed = await CircleConfirmSheet.show(
      context,
      title: 'Leave this circle?',
      message:
          'You’ll be removed from “${book.title}” and it will leave your '
          'library on this device.',
      action: 'Leave circle',
    );
    if (confirmed) await cubit.leave(bookId);
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
          onSettings: () => _openSettings(context),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
            children: [
              const SizedBox(height: 18),
              CircleMyProgressCard(
                book: book,
                cover: _coverImage,
                myNpub: state.myNpub,
                myProgressFraction: state.myProgressFraction,
                myPage: state.myPage,
              ),
              const SizedBox(height: 14),
              AppButton(
                label: 'Open book',
                icon: LucideIcons.bookOpen,
                fullWidth: true,
                onTap: () => _openBook(context),
              ),
              if (state.milestones.isNotEmpty) ...[
                const SizedBox(height: 26),
                Text(
                  'Milestones',
                  style: typography.h3.copyWith(color: colors.ink),
                ),
                const SizedBox(height: 12),
                for (final m in state.milestones.reversed)
                  _MilestoneCard(payload: m),
              ],
              const SizedBox(height: 26),
              Row(
                children: [
                  Text(
                    'Readers',
                    style: typography.h3.copyWith(color: colors.ink),
                  ),
                  const Spacer(),
                  Text(
                    'by progress',
                    style: typography.caption.copyWith(color: colors.slate2),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final entry in _sortedReaders) ...[
                CircleReaderTile(
                  entry: entry,
                  isOwner: state.isMemberAdmin(entry.npub),
                  pageCount: book.pageCount,
                  bookTitle: book.title,
                  onLongPress: entry.isSelf
                      ? null
                      : () => _readerActions(context, entry),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        CircleDetailBottomBar(
          isOwner: state.isAdmin,
          processing: state.processing,
          onDelete: () => _delete(context),
          onLeave: () => _leave(context),
        ),
      ],
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.payload});

  final MilestonePayload payload;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final pct = payload.progressPct.toStringAsFixed(1);
    final mins = (payload.sessionReadingSeconds / 60).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: colors.paper2,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Milestone ${payload.milestoneIdx + 1}',
                    style: typography.bodyL.copyWith(color: colors.ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$pct%  •  $mins min read',
                    style: typography.caption.copyWith(color: colors.slate2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(LucideIcons.zap, size: 18, color: colors.slate2),
          ],
        ),
      ),
    );
  }
}
