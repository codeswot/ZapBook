import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/core/presentation/bloc/book_download/book_download_cubit.dart';
import 'package:zapbook/core/presentation/bloc/book_download/book_download_state.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/core/presentation/widgets/circle_book_cover.dart';
import 'package:zapbook/core/presentation/widgets/book_download_overlay.dart';
import 'package:zapbook/core/presentation/widgets/bouncing_interactive_widget.dart';

class HomeContinueReadingCard extends StatelessWidget {
  const HomeContinueReadingCard({
    super.key,
    required this.book,
    required this.onTap,
    required this.onBookOpen,
    this.onLongPress,
    this.progress,
    this.pageIndex,
  });

  final CircleBook book;
  final VoidCallback onTap;
  final VoidCallback onBookOpen;
  final VoidCallback? onLongPress;
  final double? progress;
  final int? pageIndex;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: BouncingInteractiveWidget(
        onTap: onTap,
        onLongPress: onLongPress,
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
                  BookDownloadOverlay(
                    book: book,
                    child: CircleBookCover(book: book, width: 64, height: 84),
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
                          pageIndex != null
                              ? (book.pageCount > 0
                                    ? 'Page ${pageIndex! + 1} of ${book.pageCount}'
                                    : 'Reading: Page ${pageIndex! + 1}')
                              : 'Not started',
                          style: typography.bodyS.copyWith(color: colors.slate),
                        ),
                        const SizedBox(height: 6),
                        if (book.memberCount > 1)
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
                                LucideIcons.user,
                                size: 14,
                                color: colors.ink,
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
                        value: progress ?? 0.0,
                        backgroundColor: context.colors.paper4,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colors.bitcoin,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  BlocBuilder<BookDownloadCubit, BookDownloadState>(
                    builder: (context, state) {
                      return Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: colors.bitcoin,
                          shape: BoxShape.circle,
                        ),
                        child: BouncingInteractiveWidget(
                          onTap: onBookOpen,
                          child: Icon(
                            book.isDownloaded
                                ? LucideIcons.bookOpen
                                : LucideIcons.cloudDownload,
                            size: 16,
                            color: colors.bitcoinDark,
                          ),
                        ),
                      );
                    },
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
