import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:zapbook/zbf/zbf.dart';

import 'package:zapbook/features/book_reader/presentation/widgets/reading_style.dart';

class ReaderBlockView extends StatelessWidget {
  const ReaderBlockView({
    required this.block,
    required this.style,
    required this.asset,
    super.key,
  });

  final BookBlock block;
  final ReadingStyle style;
  final Uint8List? Function(String assetRef) asset;

  @override
  Widget build(BuildContext context) {
    return switch (block) {
      HeadingBlock(:final level, :final text, :final runs) => Padding(
        padding: EdgeInsets.only(top: style.paragraphSpacing * 1.5, bottom: 4),
        child: _RichText(
          text: text,
          runs: runs,
          style: style.heading.copyWith(
            fontSize: 30 - (level.clamp(1, 4) * 3).toDouble(),
          ),
        ),
      ),
      ParagraphBlock(:final text, :final runs) => Padding(
        padding: EdgeInsets.only(bottom: style.paragraphSpacing),
        child: _RichText(text: text, runs: runs, style: style.paragraph),
      ),
      PullquoteBlock(:final text, :final runs) => Padding(
        padding: EdgeInsets.only(bottom: style.paragraphSpacing),
        child: Container(
          padding: const EdgeInsets.only(left: 16),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: Theme.of(context).colorScheme.secondary,
                width: 3,
              ),
            ),
          ),
          child: _RichText(text: text, runs: runs, style: style.pullquote),
        ),
      ),
      CodeBlock(:final text) => Padding(
        padding: EdgeInsets.only(bottom: style.paragraphSpacing),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(text, style: style.code),
        ),
      ),
      CaptionBlock(:final text) => Padding(
        padding: EdgeInsets.only(bottom: style.paragraphSpacing),
        child: Text(text, style: style.caption),
      ),
      ImageBlock(:final assetRef, :final altText) => _ReaderImage(
        bytes: asset(assetRef),
        assetRef: assetRef,
        altText: altText,
        style: style,
      ),
      DividerBlock() => Padding(
        padding: EdgeInsets.symmetric(vertical: style.paragraphSpacing),
        child: const Divider(),
      ),
      PageBreakBlock() => const SizedBox.shrink(),
    };
  }
}

class _RichText extends StatelessWidget {
  const _RichText({
    required this.text,
    required this.runs,
    required this.style,
  });

  final String text;
  final List<TextRun>? runs;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final localRuns = runs;
    if (localRuns == null || localRuns.isEmpty) {
      return Text(text, style: style);
    }
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          for (final run in localRuns)
            TextSpan(text: run.text, style: _styleFor(run)),
        ],
      ),
    );
  }

  TextStyle _styleFor(TextRun run) {
    var resolved = style;
    if (run.bold) resolved = resolved.copyWith(fontWeight: FontWeight.bold);
    if (run.italic) resolved = resolved.copyWith(fontStyle: FontStyle.italic);
    if (run.code) resolved = resolved.copyWith(fontFamily: 'monospace');
    return resolved;
  }
}

class _ReaderImage extends StatelessWidget {
  const _ReaderImage({
    required this.bytes,
    required this.assetRef,
    required this.altText,
    required this.style,
  });

  final Uint8List? bytes;
  final String assetRef;
  final String altText;
  final ReadingStyle style;

  @override
  Widget build(BuildContext context) {
    final data = bytes;
    return Padding(
      padding: EdgeInsets.only(bottom: style.paragraphSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                data,
                fit: BoxFit.fitWidth,
                gaplessPlayback: true,
              ),
            )
          else
            Text('[missing image: $assetRef]', style: style.caption),
          if (altText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(altText, style: style.caption),
            ),
        ],
      ),
    );
  }
}
