import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/core/earnings/earnings_cubit.dart';
import 'package:zapbook/core/extensions/int_extension.dart';
import 'package:zapbook/features/home/domain/entities/home_dashboard.dart';
import 'package:zapbook/features/home/presentation/widgets/home_stat_card.dart';
import 'package:zapbook/theme/app_theme.dart';

class HomeStatsRow extends StatelessWidget {
  const HomeStatsRow({super.key, required this.stats});

  final HomeDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final streak = stats.dayStreak;
    final books = stats.booksRead;

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
            child: BlocBuilder<EarningsCubit, int>(
              builder: (context, sats) => HomeStatCard(
                value: sats.formatSats,
                label: 'sats earned',
                icon: LucideIcons.zap,
                color: colors.bitcoin,
              ),
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
