import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/presentation/router/app_router.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/core/presentation/widgets/book_actions_sheet.dart';
import 'package:zapbook/core/presentation/theme/app_radii.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/core/presentation/widgets/circle_book_cover.dart';
import 'package:zapbook/core/presentation/widgets/bouncing_interactive_widget.dart';
import 'package:zapbook/features/circles/presentation/widgets/admin_badge_indicator.dart';

class CircleTile extends StatelessWidget {
  const CircleTile({super.key, required this.circle});

  final CircleBook circle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return BouncingInteractiveWidget(
      onTap: () => CircleDetailRoute(circleBookId: circle.id).push(context),
      onLongPress: () => BookActionsSheet.show(context, book: circle),
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
                child: AdminBadgeIndicator(
                  circleDirId: circle.circleDirId,
                  child: CircleBookCover(book: circle, width: 72, height: 92),
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
