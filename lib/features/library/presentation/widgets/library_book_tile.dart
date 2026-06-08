import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/router/app_router.dart';
import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/features/library/presentation/bloc/library_cubit.dart';
import 'package:zapbook/features/library/presentation/widgets/book_actions_sheet.dart';
import 'package:zapbook/widgets/app_book_cover.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';
import 'package:zapbook/zbf/enums/book_source_format.dart';

class LibraryBookTile extends StatelessWidget {
  const LibraryBookTile({super.key, required this.book, this.onOpen});

  final LibraryBook book;
  final VoidCallback? onOpen;

  AppBookCoverHue get _hue {
    switch (book.sourceFormat) {
      case BookSourceFormat.pdf:
        return AppBookCoverHue.orange;
      case BookSourceFormat.epub:
        return AppBookCoverHue.purple;
      case BookSourceFormat.docx:
        return AppBookCoverHue.sky;
      case BookSourceFormat.txt:
        return AppBookCoverHue.mint;
    }
  }

  void _open(BuildContext context) {
    onOpen?.call();
    context.read<LibraryCubit>().markOpened(book.id);
    ZbfViewerRoute(zbfPath: book.zbfPath).push(context);
  }

  Future<void> _showActions(BuildContext context) async {
    final cubit = context.read<LibraryCubit>();
    final isAdmin = await cubit.isAdminOf(book.id);
    final ownerLabel = isAdmin ? '' : await cubit.ownerLabelFor(book.id);
    if (context.mounted) {
      BookActionsSheet.show(
        context,
        book: book,
        isAdmin: isAdmin,
        ownerLabel: ownerLabel,
        onDelete: () => cubit.deleteBook(book.id),
        onLeave: () => cubit.leaveCircle(book.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cover = book.coverPath;
    final image = cover != null ? FileImage(File(cover)) : null;
    return BouncingInteractiveWidget(
      onTap: () => _open(context),
      onLongPress: () => _showActions(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Stack(
            children: [
              AppBookCover(
                width: width,
                height: width / 0.727,
                hue: _hue,
                title: book.title,
                author: book.author,
                image: image,
              ),
              if (book.isShared)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(5),
                      child: Icon(
                        LucideIcons.users,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
