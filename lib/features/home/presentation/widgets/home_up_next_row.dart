import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/core/router/app_router.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/core/presentation/widgets/circle_book_cover.dart';
import 'package:zapbook/core/presentation/widgets/book_download_overlay.dart';
import 'package:zapbook/core/presentation/widgets/bouncing_interactive_widget.dart';

class HomeUpNextRow extends StatelessWidget {
  const HomeUpNextRow({
    super.key,
    required this.books,
    required this.onBookTap,
    this.onBookLongPress,
  });

  final List<CircleBook> books;
  final void Function(BuildContext, CircleBook) onBookTap;
  final void Function(BuildContext, CircleBook)? onBookLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Up next',
                style: typography.h3.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => const LibraryRoute().go(context),
                child: Text(
                  'Browse',
                  style: typography.bodyS.copyWith(
                    color: colors.bitcoin,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            scrollCacheExtent: const ScrollCacheExtent.pixels(600),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return Padding(
                padding: const EdgeInsets.only(right: 14),
                child: BouncingInteractiveWidget(
                  onTap: () => onBookTap(context, book),
                  onLongPress: onBookLongPress != null
                      ? () => onBookLongPress!(context, book)
                      : null,
                  child: Stack(
                    children: [
                      BookDownloadOverlay(
                        book: book,
                        child: CircleBookCover(
                          book: book,
                          width: 96,
                          height: 132,
                          showInfos: true,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color:
                                ((book.memberCount > 1)
                                        ? colors.plum
                                        : colors.slate)
                                    .withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            book.memberCount > 1
                                ? LucideIcons.users
                                : LucideIcons.user,
                            size: 12,
                            color: colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
