import 'package:flutter/material.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_sheet.dart';
import 'package:zapbook/zbf/zbf.dart';

class _TocChapter {
  const _TocChapter({
    required this.title,
    required this.startPage,
    required this.endPage,
  });

  final String title;
  final int startPage;
  final int endPage;

  bool contains(int page) => page >= startPage && page <= endPage;
}

class ReaderTocSheet extends StatelessWidget {
  const ReaderTocSheet({
    required this.manifest,
    required this.currentPage,
    required this.onSelect,
    super.key,
  });

  final BookManifest manifest;
  final int currentPage;
  final ValueChanged<int> onSelect;

  static Future<void> show(
    BuildContext context, {
    required BookManifest manifest,
    required int currentPage,
    required ValueChanged<int> onSelect,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.transparent,
      builder: (_) => ReaderTocSheet(
        manifest: manifest,
        currentPage: currentPage,
        onSelect: onSelect,
      ),
    );
  }

  List<_TocChapter> _chapters() {
    final total = manifest.pageCount;
    final source = manifest.chapters;
    if (source.isEmpty) {
      return [
        _TocChapter(title: manifest.title, startPage: 0, endPage: total - 1),
      ];
    }
    final result = <_TocChapter>[];
    var start = 0;
    for (var i = 0; i < source.length; i++) {
      final isLast = i == source.length - 1;
      final end = isLast
          ? total - 1
          : (start + source[i].pageCount - 1).clamp(start, total - 1);
      result.add(
        _TocChapter(title: source[i].title, startPage: start, endPage: end),
      );
      start = end + 1;
      if (start >= total) break;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final total = manifest.pageCount;
    final chapters = _chapters();

    return AppSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('Contents', style: typography.h3),
          ),
          Flexible(
            child: total == 0
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'No pages available',
                      textAlign: TextAlign.center,
                      style: typography.body.copyWith(color: colors.slate),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: chapters.length,
                    itemBuilder: (context, i) => _ChapterTile(
                      chapter: chapters[i],
                      currentPage: currentPage,
                      onSelect: (page) {
                        Navigator.of(context).pop();
                        onSelect(page);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChapterTile extends StatefulWidget {
  const _ChapterTile({
    required this.chapter,
    required this.currentPage,
    required this.onSelect,
  });

  final _TocChapter chapter;
  final int currentPage;
  final ValueChanged<int> onSelect;

  @override
  State<_ChapterTile> createState() => _ChapterTileState();
}

class _ChapterTileState extends State<_ChapterTile> {
  late bool _expanded = widget.chapter.contains(widget.currentPage);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final chapter = widget.chapter;
    final active = chapter.contains(widget.currentPage);

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: colors.transparent,
        splashColor: colors.transparent,
        highlightColor: colors.transparent,
      ),
      child: ExpansionTile(
        initiallyExpanded: _expanded,
        onExpansionChanged: (v) => setState(() => _expanded = v),
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        leading: Container(
          width: 3,
          height: 24,
          decoration: BoxDecoration(
            color: active ? colors.bitcoin : colors.hairline,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        title: Text(
          chapter.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: typography.bodyL.copyWith(
            color: active ? colors.ink : colors.slate,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${chapter.startPage + 1}',
              style: typography.caption.copyWith(
                color: colors.slate2,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 6),
            AnimatedRotation(
              duration: const Duration(milliseconds: 180),
              turns: _expanded ? 0.5 : 0,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: colors.slate,
              ),
            ),
          ],
        ),
        children: [
          for (var page = chapter.startPage; page <= chapter.endPage; page++)
            _PageRow(
              page: page,
              selected: page == widget.currentPage,
              onTap: () => widget.onSelect(page),
            ),
        ],
      ),
    );
  }
}

class _PageRow extends StatelessWidget {
  const _PageRow({
    required this.page,
    required this.selected,
    required this.onTap,
  });

  final int page;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(17, 10, 8, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Page ${page + 1}',
                style: typography.body.copyWith(
                  color: selected ? colors.bitcoin : colors.slate,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            Text(
              '${page + 1}',
              style: typography.caption.copyWith(
                color: selected ? colors.bitcoin : colors.slate2,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
