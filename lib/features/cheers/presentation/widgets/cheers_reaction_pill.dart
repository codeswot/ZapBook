import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/features/cheers/presentation/widgets/dotted_circle_painter.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class ReactionPill extends StatelessWidget {
  const ReactionPill({
    super.key,
    required this.emoji,
    required this.count,
    required this.onTap,
  });

  final String emoji;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return BouncingInteractiveWidget(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colors.paper4,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: colors.hairline2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: typography.caption.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddReactionButton extends StatelessWidget {
  const AddReactionButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BouncingInteractiveWidget(
      onTap: onTap,
      child: CustomPaint(
        painter: DottedCirclePainter(
          color: colors.bitcoin.withValues(alpha: 0.6),
        ),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(LucideIcons.zap, size: 14, color: colors.bitcoin),
        ),
      ),
    );
  }
}

class EmptyReactionsPlaceholder extends StatelessWidget {
  const EmptyReactionsPlaceholder({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BouncingInteractiveWidget(
      onTap: onTap,
      child: SizedBox(
        height: 32,
        width: 80,
        child: Stack(
          children: [
            Positioned(
              left: 24,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.paper2,
                ),
              ),
            ),
            Positioned(
              left: 12,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.paper4,
                ),
              ),
            ),
            CustomPaint(
              painter: DottedCirclePainter(color: colors.bitcoin),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.paper3,
                ),
                alignment: Alignment.center,
                child: Icon(LucideIcons.zap, size: 14, color: colors.bitcoin),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
