import 'package:equatable/equatable.dart';

final class TextRun extends Equatable {
  const TextRun(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.code = false,
  });

  final String text;
  final bool bold;
  final bool italic;
  final bool code;

  bool get isPlain => !bold && !italic && !code;

  Map<String, Object?> toJson() => {
    'text': text,
    if (bold) 'bold': true,
    if (italic) 'italic': true,
    if (code) 'code': true,
  };

  factory TextRun.fromJson(Map<String, Object?> json) {
    return TextRun(
      json['text'] as String,
      bold: json['bold'] == true,
      italic: json['italic'] == true,
      code: json['code'] == true,
    );
  }

  static List<Map<String, Object?>> encodeList(List<TextRun> runs) {
    return runs.map((run) => run.toJson()).toList();
  }

  static List<TextRun> decodeList(List<Object?> json) {
    return json
        .map((run) => TextRun.fromJson(run as Map<String, Object?>))
        .toList();
  }

  @override
  List<Object?> get props => [text, bold, italic, code];
}
