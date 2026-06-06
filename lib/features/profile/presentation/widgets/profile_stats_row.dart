import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/features/profile/domain/entities/user_profile.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_stat_card.dart';
import 'package:zapbook/theme/app_theme.dart';

class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Expanded(
          child: ProfileStatCard(
            icon: LucideIcons.flame,
            value: '${profile.dayStreak}',
            label: 'day streak',
            color: colors.coral,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ProfileStatCard(
            icon: LucideIcons.bookOpen,
            value: '${profile.booksRead}',
            label: 'books read',
            color: colors.plum,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ProfileStatCard(
            icon: LucideIcons.flag,
            value: '${profile.milestones}',
            label: 'milestones',
            color: colors.mint,
          ),
        ),
      ],
    );
  }
}
