import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/router/app_router.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/features/library/presentation/bloc/library_cubit.dart';
import 'package:zapbook/features/library/presentation/bloc/library_state.dart';
import 'package:zapbook/core/presentation/widgets/book_actions_sheet.dart';
import 'package:zapbook/core/presentation/widgets/circle_book_cover.dart';
import 'package:zapbook/core/presentation/widgets/bouncing_interactive_widget.dart';
import 'package:zapbook/theme/app_theme.dart';

class CircleBookTile extends StatelessWidget {
  const CircleBookTile({super.key, required this.book, this.onOpen});

  final CircleBook book;
  final VoidCallback? onOpen;

  void _open(BuildContext context) {
    if (!book.isDownloaded) {
      context.read<LibraryCubit>().downloadBook(book);
      return;
    }
    onOpen?.call();
    context.read<LibraryCubit>().markOpened(book.id);
    ZbfViewerRoute(
      zbfPath: book.zbfPath,
      bookTitle: book.title,
      coverPath: book.coverPath,
    ).push(context);
  }

  Future<void> _showActions(BuildContext context) async {
    if (context.mounted) {
      BookActionsSheet.show(context, book: book);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        final isDownloading =
            state is LibraryLoaded &&
            state.downloadingBookIds.contains(book.id);

        return BouncingInteractiveWidget(
          onTap: () => _open(context),
          onLongPress: () => _showActions(context),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return Stack(
                children: [
                  CircleBookCover(
                    book: book,
                    width: width,
                    height: width / 0.727,
                    showInfos: true,
                  ),
                  if (!book.isDownloaded && !isDownloading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.colors.ink.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: context.colors.paper,
                          ),
                        ),
                      ),
                    ),
                  if (book.isShared)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: context.colors.ink.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(5),
                          child: Icon(
                            LucideIcons.users,
                            size: 12,
                            color: context.colors.paper,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
