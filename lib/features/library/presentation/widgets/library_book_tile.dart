import 'dart:io';

import 'package:flutter/material.dart';

import 'package:zapbook/features/book_reader/presentation/widgets/zbf_viewer_page.dart';
import 'package:zapbook/features/library/domain/entities/library_book.dart';
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
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => ZbfViewerPage(zbfPath: book.zbfPath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cover = book.coverPath;
    final image = cover != null && File(cover).existsSync()
        ? FileImage(File(cover))
        : null;
    return BouncingInteractiveWidget(
      onTap: () => _open(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return AppBookCover(
            width: width,
            height: width / 0.727,
            hue: _hue,
            title: book.title,
            author: book.author,
            image: image,
          );
        },
      ),
    );
  }
}
