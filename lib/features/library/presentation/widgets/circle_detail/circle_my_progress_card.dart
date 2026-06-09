import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/features/library/presentation/widgets/circle_detail/circle_placeholders.dart';
import 'package:zapbook/features/library/presentation/widgets/circle_detail/circle_progress_bar.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_book_cover.dart';

class CircleMyProgressCard extends StatelessWidget {
  const CircleMyProgressCard({
    super.key,
    required this.book,
    required this.cover,
    required this.myNpub,
    required this.myProgressFraction,
    required this.myPage,
  });

  final LibraryBook book;
  final ImageProvider? cover;
  final String? myNpub;
  final double myProgressFraction;
  final int myPage;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.paper2,
        borderRadius: AppRadii.br16,
        border: Border.all(color: colors.hairline),
      ),
      child: Row(
        children: [
          Hero(
            tag: 'circle-cover-${book.id}',
            child: Material(
              type: MaterialType.transparency,
              child: AppBookCover(width: 72, height: 92, image: cover),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'YOUR PROGRESS',
                  style: typography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: colors.slate2,
                  ),
                ),
                const SizedBox(height: 6),
                CircleProgressBar(
                  value: myProgressFraction,
                  color: colors.bitcoin,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(LucideIcons.zap, size: 14, color: colors.bitcoin),
                    const SizedBox(width: 5),
                    Text(
                      '${formatSats(circleZapTotal(book.id))} sats',
                      style: typography.bodyS.copyWith(
                        color: colors.bitcoin,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'zapped in this circle',
                      style: typography.caption.copyWith(color: colors.slate2),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  book.pageCount > 0
                      ? 'Page ${myPage + 1} of ${book.pageCount}'
                      : 'Not started',
                  style: typography.bodyS.copyWith(color: colors.slate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
