import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/contact_service.dart';
import 'package:zapbook/features/library/data/marmot/book_group_datasource.dart';
import 'package:zapbook/features/library/domain/repositories/library_repository.dart';
import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/features/library/presentation/widgets/book_edit_sheet.dart';
import 'package:zapbook/features/library/presentation/widgets/circle_confirm_sheet.dart';
import 'package:zapbook/features/library/presentation/widgets/circle_members_sheet.dart';
import 'package:zapbook/features/library/presentation/widgets/share_circle_sheet.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_book_cover.dart';
import 'package:zapbook/widgets/app_sheet.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class BookActionsSheet extends StatelessWidget {
  const BookActionsSheet({
    super.key,
    required this.book,
    required this.isAdmin,
    required this.ownerLabel,
    required this.onDelete,
    required this.onLeave,
  });

  final LibraryBook book;
  final bool isAdmin;
  final String ownerLabel;
  final VoidCallback onDelete;
  final VoidCallback onLeave;

  static Future<void> show(
    BuildContext context, {
    required LibraryBook book,
    required bool isAdmin,
    required String ownerLabel,
    required VoidCallback onDelete,
    required VoidCallback onLeave,
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
        onLeave: onLeave,
      ),
    );
  }

  static Future<void> showWithId(BuildContext context, String bookId) async {
    final repository = getIt<LibraryRepository>();
    final book = await repository.getBook(bookId);
    if (book == null) return;

    final identity = getIt<IdentityLocalDataSource>();
    final datasource = getIt<BookGroupDatasource>();
    final contacts = getIt<ContactService>();

    final myNpub = await identity.readNpub();
    final admins = await datasource.adminNpubs(bookId);
    final isAdmin = myNpub != null && admins.contains(myNpub);

    String ownerLabel = '';
    if (!isAdmin && admins.isNotEmpty) {
      final contact = await contacts.resolve(admins.first);
      ownerLabel = contact.label;
    }

    if (context.mounted) {
      await showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        backgroundColor: context.colors.transparent,
        builder: (_) => BookActionsSheet(
          book: book,
          isAdmin: isAdmin,
          ownerLabel: ownerLabel,
          onDelete: () => repository.deleteBook(bookId),
          onLeave: () => repository.leaveCircle(bookId),
        ),
      );
    }
  }

  Future<void> _onDeleteTap(BuildContext context) async {
    context.pop();
    final confirmed = await CircleConfirmSheet.show(
      context,
      title: 'Delete this book?',
      message: isAdmin
          ? '“${book.title}” will be removed from your shelf and its file '
                'deleted from this device. This can’t be undone.'
          : 'You’re leaving this shared book. It’ll be removed from this '
                'device and you’ll no longer be part of its circle.',
      action: 'Delete book',
    );
    if (confirmed) (isAdmin ? onDelete : onLeave)();
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
                        style: typography.caption.copyWith(
                          color: colors.slate2,
                        ),
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
            onTap: () => _onDeleteTap(context),
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
