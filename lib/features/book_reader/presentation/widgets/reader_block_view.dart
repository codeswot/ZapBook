import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:zapbook/zbf/zbf.dart';

import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/theme/reading_style.dart';

class ReaderBlockView extends StatelessWidget {
  const ReaderBlockView({
    required this.block,
    required this.style,
    required this.asset,
    this.highlightQuery,
    this.highlightProgress,
    super.key,
  });

  final BookBlock block;
  final ReadingStyle style;
  final Uint8List? Function(String assetRef) asset;
  final String? highlightQuery;
  final double? highlightProgress;

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
          highlightQuery: highlightQuery,
          highlightProgress: highlightProgress,
        ),
      ),
      ParagraphBlock(:final text, :final runs) => Padding(
        padding: EdgeInsets.only(bottom: style.paragraphSpacing),
        child: _RichText(
          text: text,
          runs: runs,
          style: style.paragraph,
          highlightQuery: highlightQuery,
          highlightProgress: highlightProgress,
        ),
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
          child: _RichText(
            text: text,
            runs: runs,
            style: style.pullquote,
            highlightQuery: highlightQuery,
            highlightProgress: highlightProgress,
          ),
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
    this.highlightQuery,
    this.highlightProgress,
  });

  final String text;
  final List<TextRun>? runs;
  final TextStyle style;
  final String? highlightQuery;
  final double? highlightProgress;

  bool get _highlighting =>
      highlightProgress != null &&
      highlightQuery != null &&
      highlightQuery!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final localRuns = runs;
    if (localRuns == null || localRuns.isEmpty) {
      if (!_highlighting) return Text(text, style: style);
      return Text.rich(
        TextSpan(style: style, children: _spansFor(context, text, style)),
      );
    }
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          for (final run in localRuns)
            if (_highlighting)
              ..._spansFor(context, run.text, _styleFor(run))
            else
              TextSpan(text: run.text, style: _styleFor(run)),
        ],
      ),
    );
  }

  static double _envelope(double p) {
    if (p < 0.12) return p / 0.12;
    if (p > 0.75) return ((1.0 - p) / 0.25).clamp(0.0, 1.0);
    return 1.0;
  }

  List<InlineSpan> _spansFor(
    BuildContext context,
    String input,
    TextStyle base,
  ) {
    final query = highlightQuery;
    if (query == null || query.isEmpty) {
      return [TextSpan(text: input, style: base)];
    }

    final colors = context.colors;
    final p = highlightProgress ?? 0.0;
    final envelope = _envelope(p);
    final center = 0.16 + ((p * 3.0) % 1.0) * 0.68;

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          colors.nostr.withValues(alpha: 0.35 * envelope),
          colors.bitcoin2.withValues(alpha: 0.68 * envelope),
          colors.paper.withValues(alpha: 0.85 * envelope),
          colors.bitcoin2.withValues(alpha: 0.68 * envelope),
          colors.nostr.withValues(alpha: 0.35 * envelope),
        ],
        stops: [0.0, center - 0.15, center, center + 0.15, 1.0],
      ).createShader(const Rect.fromLTWH(0, 0, 280, 40));

    final highlighted = base.copyWith(
      background: paint,
      fontWeight: FontWeight.w600,
    );

    final spans = <InlineSpan>[];
    final lowerInput = input.toLowerCase();
    final lowerQuery = query.toLowerCase();

    int start = 0;
    while (true) {
      final index = lowerInput.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: input.substring(start), style: base));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: input.substring(start, index), style: base));
      }

      spans.add(
        TextSpan(
          text: input.substring(index, index + query.length),
          style: highlighted,
        ),
      );

      start = index + query.length;
    }

    return spans;
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
