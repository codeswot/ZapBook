import 'package:equatable/equatable.dart';

import 'package:zapbook/zbf/enums/book_layout_type.dart';
import 'package:zapbook/zbf/entities/book_block.dart';

final class BookPage extends Equatable {
  const BookPage({
    required this.pageNumber,
    required this.chapterIndex,
    required this.chapterTitle,
    required this.layoutType,
    required this.needsAiProcessing,
    required this.blocks,
  });

  final int pageNumber;
  final int chapterIndex;
  final String chapterTitle;
  final BookLayoutType layoutType;
  final bool needsAiProcessing;
  final List<BookBlock> blocks;

  Map<String, Object?> toJson() => {
    'pageNumber': pageNumber,
    'chapterIndex': chapterIndex,
    'chapterTitle': chapterTitle,
    'layoutType': layoutType.wireValue,
    'needsAiProcessing': needsAiProcessing,
    'blocks': blocks.map((block) => block.toJson()).toList(),
  };

  factory BookPage.fromJson(Map<String, Object?> json) {
    final rawBlocks = json['blocks'] as List<Object?>;
    return BookPage(
      pageNumber: (json['pageNumber'] as num).toInt(),
      chapterIndex: (json['chapterIndex'] as num).toInt(),
      chapterTitle: json['chapterTitle'] as String,
      layoutType: BookLayoutType.fromWire(json['layoutType'] as String),
      needsAiProcessing: json['needsAiProcessing'] as bool,
      blocks: rawBlocks
          .map((block) => BookBlock.fromJson(block as Map<String, Object?>))
          .toList(),
    );
  }

  BookPage copyWith({
    int? pageNumber,
    int? chapterIndex,
    String? chapterTitle,
    BookLayoutType? layoutType,
    bool? needsAiProcessing,
    List<BookBlock>? blocks,
  }) {
    return BookPage(
      pageNumber: pageNumber ?? this.pageNumber,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      layoutType: layoutType ?? this.layoutType,
      needsAiProcessing: needsAiProcessing ?? this.needsAiProcessing,
      blocks: blocks ?? this.blocks,
    );
  }

  @override
  List<Object?> get props => [
    pageNumber,
    chapterIndex,
    chapterTitle,
    layoutType,
    needsAiProcessing,
    blocks,
  ];
}
