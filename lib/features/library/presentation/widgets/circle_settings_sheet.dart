import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/features/library/presentation/bloc/circle_detail_cubit.dart';
import 'package:zapbook/features/library/presentation/widgets/book_edit_sheet.dart';
import 'package:zapbook/features/library/presentation/widgets/circle_members_sheet.dart';
import 'package:zapbook/features/library/presentation/widgets/circle_confirm_sheet.dart';
import 'package:zapbook/features/library/presentation/widgets/share_circle_sheet.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_book_cover.dart';
import 'package:zapbook/widgets/app_sheet.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class CircleSettingsSheet extends StatelessWidget {
  const CircleSettingsSheet({
    super.key,
    required this.cubit,
    required this.book,
    required this.isAdmin,
  });

  final CircleDetailCubit cubit;
  final LibraryBook book;
  final bool isAdmin;

  static Future<void> show(
    BuildContext context, {
    required CircleDetailCubit cubit,
    required LibraryBook book,
    required bool isAdmin,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: context.colors.transparent,
      builder: (_) =>
          CircleSettingsSheet(cubit: cubit, book: book, isAdmin: isAdmin),
    );
  }

  ImageProvider? get _cover {
    final path = book.coverPath;
    return path != null ? FileImage(File(path)) : null;
  }

  Future<void> _addReaders(BuildContext context) async {
    context.pop();
    await ShareCircleSheet.show(context, book);
    await cubit.refresh(book.id);
  }

  Future<void> _manageReaders(BuildContext context) async {
    context.pop();
    await CircleMembersSheet.show(context, book: book, isAdmin: isAdmin);
    await cubit.refresh(book.id);
  }

  Future<void> _delete(BuildContext context) async {
    context.pop();
    final ok = await CircleConfirmSheet.show(
      context,
      title: 'Delete this circle?',
      message:
          'Everyone except you will be removed from “${book.title}”. '
          'The book stays in your library as a private copy.',
      action: 'Delete circle',
    );
    if (ok) await cubit.dissolve(book.id);
  }

  Future<void> _leave(BuildContext context) async {
    context.pop();
    final ok = await CircleConfirmSheet.show(
      context,
      title: 'Leave this circle?',
      message:
          'You’ll be removed from “${book.title}” and it will leave your '
          'library on this device.',
      action: 'Leave circle',
    );
    if (ok) await cubit.leave(book.id);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return AppSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              AppBookCover(width: 44, height: 60, image: _cover),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Circle settings',
                      style: typography.h3.copyWith(color: colors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.bodyS.copyWith(color: colors.slate),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (isAdmin) ...[
            _SettingsRow(
              icon: LucideIcons.userPlus,
              label: 'Add readers',
              onTap: () => _addReaders(context),
            ),
            const SizedBox(height: 10),
            _SettingsRow(
              icon: LucideIcons.pencil,
              label: 'Edit book details',
              onTap: () {
                context.pop();
                BookEditSheet.show(context, book);
              },
            ),
            const SizedBox(height: 10),
          ],
          _SettingsRow(
            icon: LucideIcons.users,
            label: 'Manage circle readers',
            onTap: () => _manageReaders(context),
          ),
          const SizedBox(height: 10),
          if (isAdmin)
            _SettingsRow(
              icon: LucideIcons.trash2,
              label: 'Delete circle',
              tone: colors.tomato,
              onTap: () => _delete(context),
            )
          else
            _SettingsRow(
              icon: LucideIcons.logOut,
              label: 'Leave circle',
              tone: colors.tomato,
              onTap: () => _leave(context),
            ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tone,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = tone ?? colors.ink;
    return BouncingInteractiveWidget(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.paper3,
          borderRadius: AppRadii.br12,
          border: Border.all(color: colors.hairline),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: context.typography.bodyL.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 18, color: colors.slate2),
          ],
        ),
      ),
    );
  }
}
