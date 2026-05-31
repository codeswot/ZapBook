import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:zapbook/widgets/app_book_cover.dart';

@widgetbook.UseCase(
  name: 'Default',
  type: AppBookCover,
)
Widget buildAppBookCoverUseCase(BuildContext context) {
  return const Center(
    child: AppBookCover(
      title: 'The Book of Satoshi',
      author: 'Phil Champagne',
    ),
  );
}

@widgetbook.UseCase(
  name: 'With Image',
  type: AppBookCover,
)
Widget buildAppBookCoverWithImageUseCase(BuildContext context) {
  return Center(
    child: AppBookCover(
      title: 'Alice in Wonderland',
      author: 'Lewis Carroll',
      hue: AppBookCoverHue.sky,
      image: const NetworkImage(
        'https://images.unsplash.com/photo-1614113489855-66422ad300a4?w=400&q=80',
      ),
    ),
  );
}
