import 'package:zapbook/zbf/zbf.dart';

final class PageLayout {
  const PageLayout._();

  static BookLayoutType infer(List<BookBlock> blocks) {
    if (blocks.isEmpty) {
      return BookLayoutType.textHeavy;
    }
    if (blocks.first is HeadingBlock) {
      return BookLayoutType.chapterOpener;
    }
    final imageCount = blocks.whereType<ImageBlock>().length;
    if (imageCount == 0) {
      return BookLayoutType.textHeavy;
    }
    final textCount = blocks
        .where(
          (block) =>
              block is ParagraphBlock ||
              block is PullquoteBlock ||
              block is CodeBlock,
        )
        .length;
    if (textCount == 0) {
      return BookLayoutType.illustration;
    }
    return BookLayoutType.mixed;
  }
}
