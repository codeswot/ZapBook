import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/features/library/presentation/widgets/open_book.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/widgets/app_book_cover.dart';
import 'package:zapbook/widgets/app_icon_button.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class ContinueReadingCard extends StatelessWidget {
  const ContinueReadingCard({super.key, required this.book});

  final LibraryBook book;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final cover = book.coverPath;
    final image = cover != null && File(cover).existsSync()
        ? FileImage(File(cover))
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: BouncingInteractiveWidget(
        onTap: () => openBook(context, book),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.paper3,
            borderRadius: AppRadii.br16,
            border: Border.all(color: colors.hairline),
          ),
          child: Row(
            children: [
              AppBookCover(width: 56, height: 77, image: image),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'CONTINUE READING',
                      style: typography.caption.copyWith(
                        color: colors.bitcoin,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.h3.copyWith(color: colors.ink),
                    ),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.bodyS.copyWith(color: colors.slate),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AppIconButton(
                onTap: () => openBook(context, book),
                icon: LucideIcons.bookOpen,
                size: 20,
                color: colors.paper,
                backgroundColor: colors.bitcoin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
