import 'package:flutter/material.dart';
import 'package:zapbook/theme/app_theme.dart';

class ReaderHeader extends StatelessWidget {
  const ReaderHeader({
    required this.title,
    required this.chapterTitle,
    required this.onBack,
    required this.onOpenContents,
    this.onSearch,
    super.key,
  });

  final String title;
  final String chapterTitle;
  final VoidCallback onBack;
  final VoidCallback onOpenContents;
  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Container(
      decoration: BoxDecoration(
        color: colors.paper.withValues(alpha: 0.92),
        border: Border(bottom: BorderSide(color: colors.hairline)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                color: colors.ink,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.label.copyWith(color: colors.ink),
                    ),
                    if (chapterTitle.isNotEmpty)
                      Text(
                        chapterTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: typography.caption.copyWith(color: colors.slate),
                      ),
                  ],
                ),
              ),
              if (onSearch != null)
                IconButton(
                  onPressed: onSearch,
                  icon: const Icon(Icons.search_rounded),
                  tooltip: 'Search book',
                  color: colors.ink,
                ),
              IconButton(
                onPressed: onOpenContents,
                icon: const Icon(Icons.list_rounded),
                tooltip: 'Contents',
                color: colors.ink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
