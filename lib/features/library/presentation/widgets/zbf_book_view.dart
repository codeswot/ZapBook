import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_progress.dart';
import 'package:zapbook/zbf/zbf.dart';
import 'package:zapbook/features/book_ingestion/domain/ai/pdf_page_rasterizer.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/viewer/zbf_viewer_cubit.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/viewer/zbf_viewer_state.dart';
import 'package:zapbook/features/library/presentation/widgets/zb_shimmer.dart';

class ZbfViewerMessage extends StatelessWidget {
  const ZbfViewerMessage({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text, style: context.typography.body),
      ),
    );
  }
}

class ZbfBookView extends StatefulWidget {
  const ZbfBookView({required this.handle, super.key, this.rasterizer});

  final ZbfBookHandle handle;
  final PdfPageRasterizer? rasterizer;

  @override
  State<ZbfBookView> createState() => _ZbfBookViewState();
}

class _ZbfBookViewState extends State<ZbfBookView> {
  final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manifest = widget.handle.manifest;
    if (manifest.pageCount == 0) {
      return const ZbfViewerMessage(text: 'No pages were extracted');
    }
    return BlocProvider(
      create: (_) => ZbfViewerCubit(
        handle: widget.handle,
        rasterizer: widget.rasterizer,
      ),
      child: BlocBuilder<ZbfViewerCubit, ZbfViewerState>(
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: manifest.pageCount,
                  onPageChanged: (index) =>
                      context.read<ZbfViewerCubit>().pageChanged(index),
                  itemBuilder: (context, index) => _ZbfPage(
                    handle: widget.handle,
                    page: widget.handle.pageAt(index),
                    index: index,
                  ),
                ),
              ),
              _PageFooter(index: state.currentPage, total: manifest.pageCount),
            ],
          );
        },
      ),
    );
  }
}

class _ZbfPage extends StatelessWidget {
  const _ZbfPage({
    required this.handle,
    required this.page,
    required this.index,
  });

  final ZbfBookHandle handle;
  final BookPage page;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (page.layoutType == BookLayoutType.processing) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Align(
          alignment: Alignment.topLeft,
          child: ZbShimmer(message: 'Preparing page ${index + 1}…'),
        ),
      );
    }

    final body = page.layoutType == BookLayoutType.illustration
        ? BlocBuilder<ZbfViewerCubit, ZbfViewerState>(
            buildWhen: (prev, curr) =>
                prev.imagePages[index] != curr.imagePages[index] ||
                prev.rasterizingPages.contains(index) !=
                    curr.rasterizingPages.contains(index),
            builder: (context, state) {
              final rendered = state.imagePages[index];
              if (rendered != null) {
                return _PageBlocks(handle: handle, blocks: rendered);
              }
              if (state.rasterizingPages.contains(index)) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: ZbShimmer(message: 'Rendering page ${index + 1}…'),
                );
              }
              return _PageBlocks(handle: handle, blocks: page.blocks);
            },
          )
        : _PageBlocks(handle: handle, blocks: page.blocks);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(page.chapterTitle, style: context.typography.label),
          const SizedBox(height: 12),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _PageBlocks extends StatelessWidget {
  const _PageBlocks({required this.handle, required this.blocks});

  final ZbfBookHandle handle;
  final List<BookBlock> blocks;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final block in blocks)
          ZbfBlockView(block: block, asset: handle.asset),
      ],
    );
  }
}

class _PageFooter extends StatelessWidget {
  const _PageFooter({required this.index, required this.total});

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppProgress(value: (index + 1) / total),
          const SizedBox(height: 6),
          Text(
            'Page ${index + 1} of $total',
            style: context.typography.caption,
          ),
        ],
      ),
    );
  }
}

class _BlockText extends StatelessWidget {
  const _BlockText({
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
      return SelectableText(text, style: style);
    }
    return SelectableText.rich(
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
    if (run.bold) {
      resolved = resolved.copyWith(fontWeight: FontWeight.bold);
    }
    if (run.italic) {
      resolved = resolved.copyWith(fontStyle: FontStyle.italic);
    }
    if (run.code) {
      resolved = resolved.copyWith(fontFamily: 'monospace');
    }
    return resolved;
  }
}

class ZbfBlockView extends StatelessWidget {
  const ZbfBlockView({required this.block, required this.asset, super.key});

  final BookBlock block;
  final Uint8List? Function(String assetRef) asset;

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: switch (block) {
        HeadingBlock(:final level, :final text, :final runs) => _BlockText(
          text: text,
          runs: runs,
          style: typography.h3.copyWith(fontSize: 22 - (level * 2).toDouble()),
        ),
        ParagraphBlock(:final text, :final runs) => _BlockText(
          text: text,
          runs: runs,
          style: typography.body,
        ),
        PullquoteBlock(:final text, :final runs) => Container(
          padding: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: colors.bitcoin, width: 3)),
          ),
          child: _BlockText(
            text: text,
            runs: runs,
            style: typography.body.copyWith(fontStyle: FontStyle.italic),
          ),
        ),
        CodeBlock(:final text) => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.mist,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.hairline),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectableText(
              text,
              style: typography.bodyS.copyWith(
                fontFamily: 'monospace',
                height: 1.4,
                color: colors.ink,
              ),
            ),
          ),
        ),
        CaptionBlock(:final text) => SelectableText(
          text,
          style: typography.caption.copyWith(color: colors.slate),
        ),
        ImageBlock(:final assetRef, :final altText) => _ImageView(
          bytes: asset(assetRef),
          assetRef: assetRef,
          altText: altText,
        ),
        DividerBlock() => const Divider(),
        PageBreakBlock() => Text(
          '— page break —',
          style: typography.caption.copyWith(color: colors.slate2),
        ),
      },
    );
  }
}

class _ImageView extends StatelessWidget {
  const _ImageView({
    required this.bytes,
    required this.assetRef,
    required this.altText,
  });

  final Uint8List? bytes;
  final String assetRef;
  final String altText;

  @override
  Widget build(BuildContext context) {
    final data = bytes;
    return Column(
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
          Text('[missing image: $assetRef]', style: context.typography.caption),
        if (altText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(altText, style: context.typography.caption),
          ),
      ],
    );
  }
}
