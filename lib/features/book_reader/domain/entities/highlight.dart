import 'package:equatable/equatable.dart';

enum HighlightVisibility { private, circle }

final class HighlightSpan extends Equatable {
  const HighlightSpan({
    required this.originalBlockIndex,
    required this.startOffset,
    required this.endOffset,
  });

  final int originalBlockIndex;
  final int startOffset;
  final int endOffset;

  factory HighlightSpan.fromJson(Map<String, dynamic> json) => HighlightSpan(
    originalBlockIndex: json['originalBlockIndex'] as int,
    startOffset: json['startOffset'] as int,
    endOffset: json['endOffset'] as int,
  );

  Map<String, dynamic> toJson() => {
    'originalBlockIndex': originalBlockIndex,
    'startOffset': startOffset,
    'endOffset': endOffset,
  };

  @override
  List<Object?> get props => [originalBlockIndex, startOffset, endOffset];
}

final class Highlight extends Equatable {
  const Highlight({
    required this.id,
    required this.bookId,
    required this.ownerNpub,
    required this.visibility,
    this.groupId,
    required this.pageNumber,
    required this.spans,
    required this.quoteSnapshot,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.deleted = false,
  });

  final String id;
  final String bookId;
  final String ownerNpub;
  final HighlightVisibility visibility;
  final String? groupId;
  final int pageNumber;
  final List<HighlightSpan> spans;
  final String quoteSnapshot;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool deleted;

  Highlight copyWith({
    HighlightVisibility? visibility,
    String? groupId,
    String? note,
    DateTime? updatedAt,
    bool? deleted,
  }) => Highlight(
    id: id,
    bookId: bookId,
    ownerNpub: ownerNpub,
    visibility: visibility ?? this.visibility,
    groupId: groupId ?? this.groupId,
    pageNumber: pageNumber,
    spans: spans,
    quoteSnapshot: quoteSnapshot,
    note: note ?? this.note,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
  );

  @override
  List<Object?> get props => [
    id,
    bookId,
    ownerNpub,
    visibility,
    groupId,
    pageNumber,
    spans,
    quoteSnapshot,
    note,
    createdAt,
    updatedAt,
    deleted,
  ];
}
