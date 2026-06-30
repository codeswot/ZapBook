import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/theme/app_theme.dart';

class CirclesEmptyView extends StatelessWidget {
  const CirclesEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 80),
          Icon(LucideIcons.users, size: 56, color: colors.slate2),
          const SizedBox(height: 24),
          Text(
            'No circles yet',
            style: typography.h2.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Share a book with a friend to start a circle. '
            'Everyone you share with reads it together.',
            textAlign: TextAlign.center,
            style: typography.bodyS.copyWith(color: colors.slate),
          ),
        ],
      ),
    );
  }
}
