import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/features/home/presentation/widgets/home_stat_card.dart';
import 'package:zapbook/theme/app_theme.dart';

class HomeStatsRow extends StatelessWidget {
  const HomeStatsRow({super.key, required this.profile});

  final dynamic profile;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final streak = profile.dayStreak;
    final sats = profile.satsEarned;
    final books = profile.booksRead;

    final formattedSats = sats >= 1000 ? '${(sats / 1000).toStringAsFixed(0)}k' : '$sats';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: HomeStatCard(
              value: '$streak',
              label: 'day streak',
              icon: LucideIcons.flame,
              color: colors.bitcoin,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: HomeStatCard(
              value: formattedSats,
              label: 'sats earned',
              icon: LucideIcons.zap,
              color: colors.bitcoin,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: HomeStatCard(
              value: '$books',
              label: 'books done',
              icon: LucideIcons.checkCircle2,
              color: colors.positive,
            ),
          ),
        ],
      ),
    );
  }
}
