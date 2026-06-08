import 'package:flutter/material.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/theme/app_radii.dart';

class HomeStatCard extends StatelessWidget {
  const HomeStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.paper2,
        borderRadius: AppRadii.br16,
        border: Border.all(color: colors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: typography.h2.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: typography.caption.copyWith(color: colors.slate),
          ),
        ],
      ),
    );
  }
}
