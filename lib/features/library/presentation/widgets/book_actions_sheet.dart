import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/features/library/presentation/widgets/book_edit_sheet.dart';
import 'package:zapbook/features/library/presentation/widgets/circle_members_sheet.dart';
import 'package:zapbook/features/library/presentation/widgets/share_circle_sheet.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_book_cover.dart';
import 'package:zapbook/widgets/app_button.dart';
import 'package:zapbook/widgets/app_sheet.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class BookActionsSheet extends StatelessWidget {
  const BookActionsSheet({
    super.key,
    required this.book,
    required this.isAdmin,
    required this.ownerLabel,
    required this.onDelete,
  });

  final LibraryBook book;
  final bool isAdmin;
  final String ownerLabel;
  final VoidCallback onDelete;

  static Future<void> show(
    BuildContext context, {
    required LibraryBook book,
    required bool isAdmin,
    required String ownerLabel,
    required VoidCallback onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: context.colors.transparent,
      builder: (_) => BookActionsSheet(
        book: book,
        isAdmin: isAdmin,
        ownerLabel: ownerLabel,
        onDelete: onDelete,
      ),
    );
  }

  ImageProvider? get _coverImage {
    final path = book.coverPath;
    return path != null ? FileImage(File(path)) : null;
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
              AppBookCover(width: 48, height: 66, image: _coverImage),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.h3.copyWith(color: colors.ink),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          book.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: typography.bodyS.copyWith(color: colors.slate),
                        ),
                      ],
                    ),
                    if (isAdmin || ownerLabel.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        isAdmin ? 'You own this book' : 'Shared by $ownerLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: typography.caption.copyWith(color: colors.slate2),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (isAdmin) ...[
            _ActionRow(
              icon: LucideIcons.pencil,
              label: 'Edit details',
              onTap: () {
                context.pop();
                BookEditSheet.show(context, book);
              },
            ),
            const SizedBox(height: 10),
            _ActionRow(
              icon: LucideIcons.userPlus,
              label: book.isShared ? 'Add to circle' : 'Share to circle',
              onTap: () {
                context.pop();
                ShareCircleSheet.show(context, book);
              },
            ),
          ],
          if (book.isShared) ...[
            const SizedBox(height: 10),
            _ActionRow(
              icon: LucideIcons.users,
              label: 'Manage circle',
              onTap: () {
                context.pop();
                CircleMembersSheet.show(context, book: book, isAdmin: isAdmin);
              },
            ),
          ],
          const SizedBox(height: 10),
          _ActionRow(
            icon: LucideIcons.trash2,
            label: 'Delete book',
            tone: colors.tomato,
            onTap: isAdmin
                ? () {
                    context.pop();
                    unawaited(_confirmDelete(context, book).then(
                      (confirmed) { if (confirmed) onDelete(); },
                    ));
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    this.onTap,
    this.tone,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
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
            Text(
              label,
              style: context.typography.bodyL.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> _confirmDelete(BuildContext context, LibraryBook book) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    backgroundColor: context.colors.transparent,
    builder: (sheetContext) {
      final colors = sheetContext.colors;
      final typography = sheetContext.typography;
      return AppSheet(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Delete this book?', style: typography.h3),
            const SizedBox(height: 10),
            Text(
              '“${book.title}” will be removed from your shelf and its file '
              'deleted from this device. This can’t be undone.',
              style: typography.body.copyWith(color: colors.slate),
            ),
            const SizedBox(height: 28),
            AppButton(
              label: 'Delete book',
              icon: LucideIcons.trash2,
              variant: AppButtonVariant.danger,
              fullWidth: true,
              onTap: () => Navigator.of(sheetContext).pop(true),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Cancel',
              variant: AppButtonVariant.ghost,
              fullWidth: true,
              onTap: () => Navigator.of(sheetContext).pop(false),
            ),
          ],
        ),
      );
    },
  );
  return result ?? false;
}
