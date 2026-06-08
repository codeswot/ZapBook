import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/features/library/presentation/widgets/circle_detail/circle_placeholders.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/widgets/app_book_cover.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class HomeContinueReadingCard extends StatelessWidget {
  const HomeContinueReadingCard({
    super.key,
    required this.book,
    required this.onTap,
  });

  final LibraryBook book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final cover = book.coverPath;
    final image = cover != null && File(cover).existsSync()
        ? FileImage(File(cover))
        : null;

    final progress = circleProgressFraction(book.id);
    final page = circleReaderPage(book.id, book.pageCount);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: BouncingInteractiveWidget(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.paper3,
            borderRadius: AppRadii.br20,
            border: Border.all(color: colors.hairline2),
            boxShadow: [
              BoxShadow(
                color: colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBookCover(
                    width: 64,
                    height: 84,
                    title: book.title,
                    author: book.author,
                    image: image,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CONTINUE',
                          style: typography.caption.copyWith(
                            color: colors.bitcoin,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          book.title,
                          style: typography.h3.copyWith(
                            color: colors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          book.pageCount > 0
                              ? 'Page $page of ${book.pageCount}'
                              : 'Not started',
                          style: typography.bodyS.copyWith(color: colors.slate),
                        ),
                        const SizedBox(height: 6),
                        if (book.isShared)
                          Row(
                            children: [
                              Icon(
                                LucideIcons.users,
                                size: 14,
                                color: colors.plum,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${book.memberCount} reading',
                                  style: typography.caption.copyWith(
                                    color: colors.plum,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Icon(
                                LucideIcons.bookOpen,
                                size: 14,
                                color: colors.bitcoinDark,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Solo reading',
                                style: typography.caption.copyWith(
                                  color: colors.slate,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: AppRadii.br10,
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: context.colors.paper4,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colors.bitcoin,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.bitcoin,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.bookOpen,
                      size: 16,
                      color: colors.bitcoinDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
