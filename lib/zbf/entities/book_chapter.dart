import 'package:equatable/equatable.dart';

import 'package:zapbook/zbf/entities/book_page.dart';

final class BookChapter extends Equatable {
  const BookChapter({
    required this.index,
    required this.title,
    required this.pages,
  });

  final int index;
  final String title;
  final List<BookPage> pages;

  bool get needsAiProcessing => pages.any((page) => page.needsAiProcessing);

  List<Object?> toJson() => pages.map((page) => page.toJson()).toList();

  factory BookChapter.fromPages(int index, String title, List<BookPage> pages) {
    return BookChapter(index: index, title: title, pages: pages);
  }

  static BookChapter fromJson(int index, List<Object?> json) {
    final pages = json
        .map((page) => BookPage.fromJson(page as Map<String, Object?>))
        .toList();
    final title = pages.isEmpty ? '' : pages.first.chapterTitle;
    return BookChapter(index: index, title: title, pages: pages);
  }

  BookChapter copyWith({int? index, String? title, List<BookPage>? pages}) {
    return BookChapter(
      index: index ?? this.index,
      title: title ?? this.title,
      pages: pages ?? this.pages,
    );
  }

  @override
  List<Object?> get props => [index, title, pages];
}
