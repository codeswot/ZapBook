import 'package:zapbook/zbf/zbf.dart';

class BookChunk {
  const BookChunk({
    required this.pageNumber,
    required this.seq,
    required this.text,
  });

  final int pageNumber;
  final int seq;
  final String text;
}

class BookChunker {
  const BookChunker({this.targetWords = 180, this.maxWords = 220});

  static final RegExp _whitespace = RegExp(r'\s+');

  final int targetWords;
  final int maxWords;

  List<BookChunk> chunkPage(BookPage page, {required int startSeq}) {
    final paragraphs = _paragraphsOf(page);
    if (paragraphs.isEmpty) return const [];

    final chunks = <BookChunk>[];
    final current = StringBuffer();
    var currentWords = 0;
    var seq = startSeq;

    void flush() {
      if (currentWords == 0) return;
      chunks.add(
        BookChunk(
          pageNumber: page.pageNumber,
          seq: seq++,
          text: current.toString().trim(),
        ),
      );
      current.clear();
      currentWords = 0;
    }

    for (final paragraph in paragraphs) {
      final words = paragraph.split(_whitespace);
      if (words.length > maxWords) {
        flush();
        for (var start = 0; start < words.length; start += targetWords) {
          final end = start + targetWords > words.length
              ? words.length
              : start + targetWords;
          for (var i = start; i < end; i++) {
            if (i > start) current.write(' ');
            current.write(words[i]);
          }
          currentWords = end - start;
          flush();
        }
        continue;
      }
      if (currentWords + words.length > maxWords) flush();
      if (currentWords > 0) current.write('\n');
      current.write(paragraph);
      currentWords += words.length;
      if (currentWords >= targetWords) flush();
    }
    flush();
    return chunks;
  }

  List<String> _paragraphsOf(BookPage page) {
    final paragraphs = <String>[];
    for (final block in page.blocks) {
      final text = switch (block) {
        HeadingBlock(:final text) => text,
        ParagraphBlock(:final text) => text,
        PullquoteBlock(:final text) => text,
        CaptionBlock(:final text) => text,
        _ => '',
      };
      final trimmed = text.trim();
      if (trimmed.isNotEmpty) paragraphs.add(trimmed);
    }
    return paragraphs;
  }
}
