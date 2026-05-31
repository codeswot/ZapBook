import 'package:zapbook/zbf/zbf.dart';

List<TextRun>? styledRunsOrNull(List<TextRun> runs) {
  final merged = mergeRuns(runs);
  if (merged.isEmpty || merged.every((run) => run.isPlain)) {
    return null;
  }
  return merged;
}

List<TextRun> mergeRuns(List<TextRun> runs) {
  final merged = <TextRun>[];
  for (final run in runs) {
    final last = merged.isEmpty ? null : merged.last;
    if (last != null &&
        last.bold == run.bold &&
        last.italic == run.italic &&
        last.code == run.code) {
      merged
        ..removeLast()
        ..add(
          TextRun(
            last.text + run.text,
            bold: run.bold,
            italic: run.italic,
            code: run.code,
          ),
        );
    } else {
      merged.add(run);
    }
  }
  if (merged.isNotEmpty) {
    merged[0] = _trim(merged.first, leading: true);
    merged[merged.length - 1] = _trim(merged.last, leading: false);
  }
  return merged.where((run) => run.text.isNotEmpty).toList();
}

TextRun _trim(TextRun run, {required bool leading}) {
  final pattern = leading ? RegExp(r'^\s+') : RegExp(r'\s+$');
  return TextRun(
    run.text.replaceFirst(pattern, ''),
    bold: run.bold,
    italic: run.italic,
    code: run.code,
  );
}
