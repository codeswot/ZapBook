import 'package:flutter/material.dart';
import 'package:zapbook/theme/app_radii.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_avatar.dart';

class CelebrationReaction {
  final String emoji;
  final String count;
  const CelebrationReaction({required this.emoji, required this.count});
}

class AppCelebrationCard extends StatelessWidget {
  final String emoji;
  final String name;
  final String action;
  final String time;
  final String book;
  final String? score;
  final List<CelebrationReaction> reactions;
  final bool unread;
  final bool compact;

  const AppCelebrationCard({
    super.key,
    required this.emoji,
    required this.name,
    required this.action,
    required this.time,
    required this.book,
    this.score,
    this.reactions = const [],
    this.unread = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final semanticColors = context.colors;
    final typography = context.typography;

    return Container(
      padding: EdgeInsets.all(compact ? 16.0 : 17.0),
      decoration: BoxDecoration(
        color: semanticColors.paper2,
        borderRadius: AppRadii.br18,
        border: Border(
          top: BorderSide(
            color: unread
                ? semanticColors.bitcoinTint2
                : semanticColors.ink.withValues(alpha: 0.09),
          ),
          right: BorderSide(
            color: unread
                ? semanticColors.bitcoinTint2
                : semanticColors.ink.withValues(alpha: 0.09),
          ),
          bottom: BorderSide(
            color: unread
                ? semanticColors.bitcoinTint2
                : semanticColors.ink.withValues(alpha: 0.09),
          ),
          left: BorderSide(
            color: unread
                ? semanticColors.bitcoin
                : (unread
                      ? semanticColors.bitcoinTint2
                      : semanticColors.ink.withValues(alpha: 0.09)),
            width: unread ? 3.0 : 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(emoji: emoji, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: typography.body.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                          height: 1.35,
                          color: semanticColors.ink,
                        ),
                        children: [
                          TextSpan(
                            text: name,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(text: ' $action'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 7,
                      runSpacing: 4,
                      children: [
                        Text(
                          book,
                          style: typography.body.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 12.5,
                            height: 1.2,
                            color: semanticColors.slate,
                          ),
                        ),
                        if (score != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.check,
                                size: 13,
                                color: semanticColors.positive,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                score!,
                                style: typography.mono.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  height: 1.0,
                                  color: semanticColors.positive,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                time,
                style: typography.mono.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 11.5,
                  height: 1.0,
                  color: semanticColors.slate,
                ),
              ),
            ],
          ),
          if (reactions.isNotEmpty) ...[
            const SizedBox(height: 13),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: reactions.map((r) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: semanticColors.paper,
                    borderRadius: AppRadii.br999,
                    border: Border.all(
                      color: semanticColors.ink.withValues(alpha: 0.09),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        r.emoji,
                        style: const TextStyle(fontSize: 15, height: 1.0),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        r.count,
                        style: typography.mono.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          height: 1.0,
                          color: semanticColors.slate2,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
