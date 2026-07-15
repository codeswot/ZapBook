import 'dart:io';

import 'package:flutter/material.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/core/presentation/widgets/app_book_cover.dart';
import 'package:zapbook/core/data/infrastructure/circle_store_service.dart';
import 'package:zapbook/zbf/enums/book_source_format.dart';

class CircleBookCover extends StatelessWidget {
  const CircleBookCover({
    super.key,
    required this.book,
    required this.width,
    required this.height,
    this.showInfos = false,
  });

  final CircleBook book;
  final double width;
  final double height;
  final bool showInfos;

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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, String>>(
      stream: getIt<CircleStoreService>().watchUploadingCovers,
      initialData: getIt<CircleStoreService>().currentUploadingCovers,
      builder: (context, snapshot) {
        final uploadingCovers = snapshot.data ?? const {};
        final blurhash = uploadingCovers[book.id];
        final coverPath = book.coverPath;

        ImageProvider? image;
        if (coverPath != null) {
          image = FileImage(File(coverPath));
        }

        return AppBookCover(
          width: width,
          height: height,
          hue: _hue,
          title: book.title,
          author: book.author,
          image: image,
          blurhash: blurhash,
          showInfos: showInfos,
        );
      },
    );
  }
}
