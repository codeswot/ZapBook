import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class CircleDetailTopBar extends StatelessWidget {
  const CircleDetailTopBar({
    super.key,
    required this.readersCount,
    required this.bookId,
    required this.bookTitle,
    this.onSettings,
  });

  final int readersCount;
  final String bookId;
  final String bookTitle;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BackButton(onPressed: () => context.pop()),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'READING TOGETHER',
                style: typography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: colors.nostr,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Hero(
                tag: 'circle-title-$bookId',
                child: Material(
                  type: MaterialType.transparency,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 200),
                    child: Text(
                      bookTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.h1.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          if (onSettings != null)
            _ReadersChip(count: readersCount, onTap: onSettings!),
        ],
      ),
    );
  }
}

class _ReadersChip extends StatelessWidget {
  const _ReadersChip({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return BouncingInteractiveWidget(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.nostrTint,
          borderRadius: AppRadii.br999,
          border: Border.all(color: colors.nostrTint2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.users, size: 15, color: colors.nostr),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: typography.bodyS.copyWith(
                color: colors.nostr,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Icon(LucideIcons.settings, size: 15, color: colors.nostr),
          ],
        ),
      ),
    );
  }
}
