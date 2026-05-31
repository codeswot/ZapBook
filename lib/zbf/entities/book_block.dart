import 'package:equatable/equatable.dart';

import 'package:zapbook/zbf/entities/text_run.dart';

sealed class BookBlock extends Equatable {
  const BookBlock();

  String get type;

  Map<String, Object?> toJson();

  static BookBlock fromJson(Map<String, Object?> json) {
    final type = json['type'] as String;
    return switch (type) {
      'heading' => HeadingBlock(
        level: (json['level'] as num).toInt(),
        text: json['text'] as String,
        runs: _readRuns(json),
      ),
      'paragraph' => ParagraphBlock(
        text: json['text'] as String,
        runs: _readRuns(json),
      ),
      'image' => ImageBlock(
        assetRef: json['assetRef'] as String,
        altText: (json['altText'] as String?) ?? '',
      ),
      'pullquote' => PullquoteBlock(
        text: json['text'] as String,
        runs: _readRuns(json),
      ),
      'caption' => CaptionBlock(text: json['text'] as String),
      'code' => CodeBlock(
        text: json['text'] as String,
        language: json['language'] as String?,
      ),
      'divider' => const DividerBlock(),
      'pageBreak' => const PageBreakBlock(),
      _ => throw ArgumentError.value(type, 'type', 'Unknown BookBlock type'),
    };
  }

  @override
  bool get stringify => true;

  static List<TextRun>? _readRuns(Map<String, Object?> json) {
    final raw = json['runs'] as List<Object?>?;
    return raw == null ? null : TextRun.decodeList(raw);
  }
}

final class HeadingBlock extends BookBlock {
  const HeadingBlock({required this.level, required this.text, this.runs});

  final int level;
  final String text;
  final List<TextRun>? runs;

  @override
  String get type => 'heading';

  @override
  Map<String, Object?> toJson() {
    final localRuns = runs;
    return {
      'type': type,
      'level': level,
      'text': text,
      if (localRuns != null) 'runs': TextRun.encodeList(localRuns),
    };
  }

  @override
  List<Object?> get props => [level, text, runs];
}

final class ParagraphBlock extends BookBlock {
  const ParagraphBlock({required this.text, this.runs});

  final String text;
  final List<TextRun>? runs;

  @override
  String get type => 'paragraph';

  @override
  Map<String, Object?> toJson() {
    final localRuns = runs;
    return {
      'type': type,
      'text': text,
      if (localRuns != null) 'runs': TextRun.encodeList(localRuns),
    };
  }

  @override
  List<Object?> get props => [text, runs];
}

final class ImageBlock extends BookBlock {
  const ImageBlock({required this.assetRef, this.altText = ''});

  final String assetRef;
  final String altText;

  @override
  String get type => 'image';

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'assetRef': assetRef,
    'altText': altText,
  };

  @override
  List<Object?> get props => [assetRef, altText];
}

final class PullquoteBlock extends BookBlock {
  const PullquoteBlock({required this.text, this.runs});

  final String text;
  final List<TextRun>? runs;

  @override
  String get type => 'pullquote';

  @override
  Map<String, Object?> toJson() {
    final localRuns = runs;
    return {
      'type': type,
      'text': text,
      if (localRuns != null) 'runs': TextRun.encodeList(localRuns),
    };
  }

  @override
  List<Object?> get props => [text, runs];
}

final class CodeBlock extends BookBlock {
  const CodeBlock({required this.text, this.language});

  final String text;
  final String? language;

  @override
  String get type => 'code';

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'text': text,
    'language': language,
  };

  @override
  List<Object?> get props => [text, language];
}

final class CaptionBlock extends BookBlock {
  const CaptionBlock({required this.text});

  final String text;

  @override
  String get type => 'caption';

  @override
  Map<String, Object?> toJson() => {'type': type, 'text': text};

  @override
  List<Object?> get props => [text];
}

final class DividerBlock extends BookBlock {
  const DividerBlock();

  @override
  String get type => 'divider';

  @override
  Map<String, Object?> toJson() => {'type': type};

  @override
  List<Object?> get props => const [];
}

final class PageBreakBlock extends BookBlock {
  const PageBreakBlock();

  @override
  String get type => 'pageBreak';

  @override
  Map<String, Object?> toJson() => {'type': type};

  @override
  List<Object?> get props => const [];
}
