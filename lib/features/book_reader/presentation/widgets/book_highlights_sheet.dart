import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/presentation/theme/app_radii.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/core/presentation/widgets/app_loading_list.dart';
import 'package:zapbook/core/presentation/widgets/app_sheet.dart';
import 'package:zapbook/core/presentation/widgets/app_toast.dart';
import 'package:zapbook/core/presentation/widgets/bouncing_interactive_widget.dart';
import 'package:zapbook/features/book_reader/domain/entities/highlight.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/highlights/book_highlights_cubit.dart';

class BookHighlightsSheet extends StatelessWidget {
  const BookHighlightsSheet({
    super.key,
    required this.bookId,
    required this.groupId,
    required this.onJumpToPage,
  });

  final String bookId;
  final String groupId;
  final ValueChanged<int> onJumpToPage;

  static Future<void> show(
    BuildContext context, {
    required String bookId,
    required String groupId,
    required ValueChanged<int> onJumpToPage,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: context.colors.transparent,
      builder: (_) => BlocProvider(
        create: (_) => getIt<BookHighlightsCubit>()..load(bookId),
        child: BookHighlightsSheet(
          bookId: bookId,
          groupId: groupId,
          onJumpToPage: onJumpToPage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return AppSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Highlights & Notes',
            style: typography.displayM.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: BlocBuilder<BookHighlightsCubit, BookHighlightsState>(
              builder: (context, state) {
                if (state is BookHighlightsLoading) {
                  return const AppLoadingList(itemCount: 4);
                }
                final highlights = (state as BookHighlightsLoaded).highlights;
                if (highlights.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No highlights yet — select text while reading to add one.',
                      textAlign: TextAlign.center,
                      style: typography.body.copyWith(color: colors.slate),
                    ),
                  );
                }
                final sorted = [...highlights]
                  ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: sorted.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) => _HighlightTile(
                    highlight: sorted[index],
                    groupId: groupId,
                    onJumpToPage: onJumpToPage,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _HighlightTile extends StatelessWidget {
  const _HighlightTile({
    required this.highlight,
    required this.groupId,
    required this.onJumpToPage,
  });

  final Highlight highlight;
  final String groupId;
  final ValueChanged<int> onJumpToPage;

  void _jump(BuildContext context) {
    Navigator.of(context).pop();
    onJumpToPage(highlight.pageNumber - 1);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final canShareToCircle =
        groupId.isNotEmpty &&
        highlight.visibility == HighlightVisibility.private;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.paper3,
        borderRadius: AppRadii.br12,
        border: Border.all(color: colors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: BouncingInteractiveWidget(
                  onTap: () => _jump(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.quote, size: 14, color: colors.bitcoin),
                      const SizedBox(width: 6),
                      Text(
                        'Page ${highlight.pageNumber}',
                        style: typography.caption.copyWith(
                          color: colors.slate,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (highlight.visibility == HighlightVisibility.circle)
                Icon(LucideIcons.users, size: 14, color: colors.nostr),
              if (canShareToCircle)
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: BouncingInteractiveWidget(
                    onTap: () => context
                        .read<BookHighlightsCubit>()
                        .shareToCircle(highlight.id, groupId),
                    child: Icon(
                      LucideIcons.share2,
                      size: 16,
                      color: colors.slate,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: BouncingInteractiveWidget(
                  onTap: () {
                    context.read<BookHighlightsCubit>().deleteHighlight(
                      highlight.id,
                    );
                    context.toast.showInfo(
                      'Highlight deleted',
                      rootNavigator: true,
                    );
                  },
                  child: Icon(
                    LucideIcons.trash2,
                    size: 16,
                    color: colors.tomato,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          BouncingInteractiveWidget(
            onTap: () => _jump(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"${highlight.quoteSnapshot}"',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: typography.body.copyWith(
                    color: colors.ink,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (highlight.note != null && highlight.note!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.paper,
                      borderRadius: AppRadii.br8,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          LucideIcons.notebookPen,
                          size: 14,
                          color: colors.slate,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            highlight.note!,
                            style: typography.bodyS.copyWith(
                              color: colors.slate,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
