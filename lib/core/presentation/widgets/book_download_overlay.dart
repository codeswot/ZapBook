import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/core/presentation/bloc/book_download/book_download_cubit.dart';
import 'package:zapbook/core/presentation/bloc/book_download/book_download_state.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';

class BookDownloadOverlay extends StatelessWidget {
  const BookDownloadOverlay({
    super.key,
    required this.book,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  final CircleBook book;
  final Widget child;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookDownloadCubit, BookDownloadState>(
      builder: (context, state) {
        final isDownloading = state.downloadingBookIds.contains(book.id);

        return Stack(
          fit: StackFit.passthrough,
          children: [
            child,
            if (!book.isDownloaded && !isDownloading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colors.ink.withValues(alpha: 0.5),
                    borderRadius: borderRadius,
                  ),
                  child: Center(
                    child: Icon(
                      LucideIcons.cloudDownload,
                      color: context.colors.paper,
                      size: 32,
                    ),
                  ),
                ),
              ),
            if (isDownloading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colors.ink.withValues(alpha: 0.5),
                    borderRadius: borderRadius,
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: context.colors.paper,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
