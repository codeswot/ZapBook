import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/theme/app_radii.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.streakCount});

  final int streakCount;

  static final DateFormat _dayFormat = DateFormat('EEEE');

  String _getGreeting() {
    final now = DateTime.now();
    final dayName = _dayFormat.format(now).toUpperCase();
    final hour = now.hour;
    if (hour < 12) {
      return '$dayName MORNING';
    } else if (hour < 17) {
      return '$dayName AFTERNOON';
    } else {
      return '$dayName EVENING';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.hairline)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getGreeting(),
                style: typography.caption.copyWith(
                  color: colors.bitcoin,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'ZapBook',
                style: typography.h1.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.paper2,
              borderRadius: AppRadii.br20,
              border: Border.all(color: colors.hairline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.flame, size: 16, color: colors.bitcoin),
                const SizedBox(width: 6),
                Text(
                  '$streakCount',
                  style: typography.body.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
