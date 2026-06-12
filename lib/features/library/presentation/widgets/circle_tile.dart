import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/router/app_router.dart';
import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/features/library/presentation/widgets/book_actions_sheet.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_book_cover.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';
import 'package:zapbook/zbf/enums/book_source_format.dart';

class CircleTile extends StatelessWidget {
  const CircleTile({super.key, required this.circle});

  final LibraryBook circle;

  AppBookCoverHue get _hue {
    switch (circle.sourceFormat) {
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final cover = circle.coverPath;
    final image = cover != null ? FileImage(File(cover)) : null;

    return BouncingInteractiveWidget(
      onTap: () => CircleDetailRoute(bookId: circle.id).push(context),
      onLongPress: () => BookActionsSheet.showWithId(context, circle.id),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.paper,
          borderRadius: AppRadii.br16,
          border: Border.all(color: colors.ink.withValues(alpha: 0.09)),
        ),
        child: Row(
          children: [
            Hero(
              tag: 'circle-cover-${circle.id}',
              child: Material(
                type: MaterialType.transparency,
                child: AppBookCover(
                  width: 72,
                  height: 92,
                  hue: _hue,
                  image: image,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Hero(
                    tag: 'circle-title-${circle.id}',
                    child: Material(
                      type: MaterialType.transparency,
                      child: Text(
                        circle.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: typography.bodyL.copyWith(
                          color: colors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  Text(
                    circle.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.bodyS.copyWith(color: colors.slate),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${circle.memberCount} reading',
                    style: typography.bodyS.copyWith(
                      color: colors.slate2,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(LucideIcons.chevronRight, size: 20, color: colors.slate2),
          ],
        ),
      ),
    );
  }
}
