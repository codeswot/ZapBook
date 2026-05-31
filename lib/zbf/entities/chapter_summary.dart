import 'package:equatable/equatable.dart';

final class ChapterSummary extends Equatable {
  const ChapterSummary({
    required this.index,
    required this.title,
    required this.pageCount,
  });

  final int index;
  final String title;
  final int pageCount;

  Map<String, Object?> toJson() => {
    'index': index,
    'title': title,
    'pageCount': pageCount,
  };

  factory ChapterSummary.fromJson(Map<String, Object?> json) {
    return ChapterSummary(
      index: (json['index'] as num).toInt(),
      title: json['title'] as String,
      pageCount: (json['pageCount'] as num).toInt(),
    );
  }

  @override
  List<Object?> get props => [index, title, pageCount];
}
