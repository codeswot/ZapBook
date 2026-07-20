import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/core/presentation/theme/app_radii.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/core/presentation/widgets/app_loading_list.dart';
import 'package:zapbook/core/presentation/widgets/app_sheet.dart';
import 'package:zapbook/core/presentation/widgets/bouncing_interactive_widget.dart';
import 'package:zapbook/core/presentation/widgets/circle_book_cover.dart';
import 'package:zapbook/features/circles/domain/entities/admin_action_item.dart';
import 'package:zapbook/features/circles/presentation/bloc/admin_actions_cubit.dart';
import 'package:zapbook/features/circles/presentation/bloc/admin_actions_state.dart';

class AdminActionsSheet extends StatelessWidget {
  const AdminActionsSheet({super.key, required this.book});

  final CircleBook book;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminActionsCubit>()..load(book),
      child: const _Body(),
    );
  }

  static Future<void> show(BuildContext context, {required CircleBook book}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: context.colors.transparent,
      builder: (_) => AdminActionsSheet(book: book),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return BlocBuilder<AdminActionsCubit, AdminActionsState>(
      builder: (context, state) {
        final failedUploads = state is AdminActionsLoaded
            ? state.items.where((i) => i.hasFailedUpload).toList()
            : const <AdminActionItem>[];
        final reseedRequests = state is AdminActionsLoaded
            ? state.items.where((i) => i.hasReseedRequests).toList()
            : const <AdminActionItem>[];

        return AppSheet(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Admin actions',
                  style: typography.h3.copyWith(color: colors.ink),
                ),
                const SizedBox(height: 14),
                if (state is AdminActionsLoading)
                  const AppLoadingList()
                else if (failedUploads.isEmpty && reseedRequests.isEmpty)
                  Text(
                    'Nothing needs attention right now.',
                    style: typography.body.copyWith(color: colors.slate),
                  )
                else ...[
                  if (failedUploads.isNotEmpty) ...[
                    Text(
                      'Failed uploads',
                      style: typography.bodyS.copyWith(
                        color: colors.slate,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final item in failedUploads) ...[
                      _AdminActionRow(
                        item: item,
                        busy: (state as AdminActionsLoaded).isBusy(
                          item.book.circleDirId,
                        ),
                        subtitle:
                            'Upload failed after ${item.pendingUpload!.attempts} attempt(s)',
                        actionLabel: 'Retry',
                        onAction: () =>
                            context.read<AdminActionsCubit>().retryUpload(item),
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 8),
                  ],
                  if (reseedRequests.isNotEmpty) ...[
                    Text(
                      'Reseed requests',
                      style: typography.bodyS.copyWith(
                        color: colors.slate,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final item in reseedRequests) ...[
                      _AdminActionRow(
                        item: item,
                        busy: (state as AdminActionsLoaded).isBusy(
                          item.book.circleDirId,
                        ),
                        subtitle:
                            '${item.reseedRequesterNpubs.length} reader(s) asked for a re-upload',
                        actionLabel: 'Re-upload',
                        onAction: () =>
                            context.read<AdminActionsCubit>().reseed(item),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AdminActionRow extends StatelessWidget {
  const _AdminActionRow({
    required this.item,
    required this.busy,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final AdminActionItem item;
  final bool busy;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.paper3,
        borderRadius: AppRadii.br12,
        border: Border.all(color: colors.hairline),
      ),
      child: Row(
        children: [
          CircleBookCover(book: item.book, width: 36, height: 50),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.bodyL.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: typography.bodyS.copyWith(color: colors.slate),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (busy)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            BouncingInteractiveWidget(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colors.bitcoin,
                  borderRadius: AppRadii.br8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.refreshCw, size: 14, color: colors.paper),
                    const SizedBox(width: 6),
                    Text(
                      actionLabel,
                      style: typography.bodyS.copyWith(
                        color: colors.paper,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
