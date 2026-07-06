import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';

class CircleRemovedBanner extends StatelessWidget {
  const CircleRemovedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.coralTint,
        borderRadius: AppRadii.br12,
        border: Border.all(color: colors.coral.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.userMinus, size: 20, color: colors.coral),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You've been removed from this circle",
                  style: typography.label.copyWith(color: colors.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  'You can still read your downloaded copy, but progress no '
                  'longer syncs with the group.',
                  style: typography.bodyS.copyWith(color: colors.slate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
