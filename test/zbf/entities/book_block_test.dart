import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/zbf/entities/book_block.dart';
import 'package:zapbook/zbf/entities/text_run.dart';

void main() {
  group('BookBlock', () {
    test('HeadingBlock serialization', () {
      final block = HeadingBlock(
        level: 1,
        text: 'Title',
        runs: [const TextRun('Title', bold: true)],
      );

      final json = block.toJson();
      expect(json['type'], 'heading');
      expect(json['level'], 1);
      expect(json['text'], 'Title');
      expect(json['runs'], isNotNull);

      final parsed = BookBlock.fromJson(json);
      expect(parsed, isA<HeadingBlock>());
      expect((parsed as HeadingBlock).level, 1);
      expect(parsed.text, 'Title');
      expect(parsed.runs!.first.bold, true);
    });

    test('ParagraphBlock serialization', () {
      final block = ParagraphBlock(text: 'Hello');

      final json = block.toJson();
      expect(json['type'], 'paragraph');
      expect(json['text'], 'Hello');
      expect(json['runs'], isNull);

      final parsed = BookBlock.fromJson(json);
      expect(parsed, isA<ParagraphBlock>());
      expect((parsed as ParagraphBlock).text, 'Hello');
      expect(parsed.runs, isNull);
    });

    test('ImageBlock serialization', () {
      final block = ImageBlock(assetRef: 'img.png', altText: 'An image');

      final json = block.toJson();
      expect(json['type'], 'image');
      expect(json['assetRef'], 'img.png');
      expect(json['altText'], 'An image');

      final parsed = BookBlock.fromJson(json);
      expect(parsed, isA<ImageBlock>());
      expect((parsed as ImageBlock).assetRef, 'img.png');
      expect(parsed.altText, 'An image');
    });

    test('PullquoteBlock serialization', () {
      final block = PullquoteBlock(text: 'Quote');

      final json = block.toJson();
      expect(json['type'], 'pullquote');

      final parsed = BookBlock.fromJson(json);
      expect(parsed, isA<PullquoteBlock>());
      expect((parsed as PullquoteBlock).text, 'Quote');
    });

    test('CaptionBlock serialization', () {
      final block = CaptionBlock(text: 'Caption');

      final json = block.toJson();
      expect(json['type'], 'caption');

      final parsed = BookBlock.fromJson(json);
      expect(parsed, isA<CaptionBlock>());
      expect((parsed as CaptionBlock).text, 'Caption');
    });

    test('CodeBlock serialization', () {
      final block = CodeBlock(text: 'print()', language: 'python');

      final json = block.toJson();
      expect(json['type'], 'code');
      expect(json['language'], 'python');

      final parsed = BookBlock.fromJson(json);
      expect(parsed, isA<CodeBlock>());
      expect((parsed as CodeBlock).text, 'print()');
      expect(parsed.language, 'python');
    });

    test('DividerBlock serialization', () {
      final block = DividerBlock();
      final json = block.toJson();
      expect(json['type'], 'divider');

      final parsed = BookBlock.fromJson(json);
      expect(parsed, isA<DividerBlock>());
    });

    test('PageBreakBlock serialization', () {
      final block = PageBreakBlock();
      final json = block.toJson();
      expect(json['type'], 'pageBreak');

      final parsed = BookBlock.fromJson(json);
      expect(parsed, isA<PageBreakBlock>());
    });

    test('fromJson throws on unknown type', () {
      expect(
        () => BookBlock.fromJson({'type': 'unknown'}),
        throwsArgumentError,
      );
    });
  });
}
