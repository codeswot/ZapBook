import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/features/library/presentation/bloc/circle_members_cubit.dart';
import 'package:zapbook/features/library/presentation/bloc/circle_members_state.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_loading_list.dart';
import 'package:zapbook/widgets/app_profile_avatar.dart';
import 'package:zapbook/widgets/app_sheet.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class CircleMembersSheet extends StatelessWidget {
  const CircleMembersSheet({
    super.key,
    required this.book,
    required this.isAdmin,
  });

  final LibraryBook book;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = getIt<CircleMembersCubit>();
        cubit.load(book.id, isAdmin);
        return cubit;
      },
      child: _Body(book: book),
    );
  }

  static Future<void> show(
    BuildContext context, {
    required LibraryBook book,
    required bool isAdmin,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: context.colors.transparent,
      builder: (_) => CircleMembersSheet(book: book, isAdmin: isAdmin),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.book});
  final LibraryBook book;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CircleMembersCubit, CircleMembersState>(
      builder: (context, state) {
        final colors = context.colors;
        final typography = context.typography;
        final cubit = context.read<CircleMembersCubit>();

        final entries = state is CircleMembersLoaded
            ? state.entries
            : state is CircleMembersBusy
            ? state.entries
            : <MemberEntry>[];
        final isAdmin = state is CircleMembersLoaded
            ? state.isAdmin
            : state is CircleMembersBusy
            ? state.isAdmin
            : false;
        final busyNpub = state is CircleMembersBusy ? state.busyNpub : null;

        return AppSheet(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Circle members', style: typography.h3),
                const SizedBox(height: 14),
                if (state is CircleMembersLoading)
                  const AppLoadingList()
                else if (entries.isEmpty)
                  Text(
                    'No members yet.',
                    style: typography.body.copyWith(color: colors.slate),
                  )
                else
                  for (final entry in entries) ...[
                    Row(
                      children: [
                        AppProfileAvatar(
                          url: entry.contact.picture ?? '',
                          size: 36,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                entry.contact.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: typography.bodyL.copyWith(
                                  color: colors.ink,
                                ),
                              ),
                              Text(
                                entry.contact.shortNpub,
                                style: typography.bodyS.copyWith(
                                  color: colors.slate,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (busyNpub == entry.npub)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else if (entry.isSelf)
                          Text(
                            '(You)',
                            style: typography.bodyS.copyWith(
                              color: colors.slate2,
                            ),
                          )
                        else ...[
                          if (isAdmin)
                            BouncingInteractiveWidget(
                              onTap: () => cubit.remove(book.id, entry.npub),
                              child: Icon(
                                LucideIcons.userMinus,
                                size: 20,
                                color: colors.tomato,
                              ),
                            ),
                          if (!entry.isContact) ...[
                            const SizedBox(width: 10),
                            BouncingInteractiveWidget(
                              onTap: () => cubit.addContact(entry.npub),
                              child: Icon(
                                LucideIcons.userPlus,
                                size: 20,
                                color: colors.bitcoin,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          ),
        );
      },
    );
  }
}
