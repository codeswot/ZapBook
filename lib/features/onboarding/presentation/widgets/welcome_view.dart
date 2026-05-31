import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_button.dart';

class WelcomeView extends StatelessWidget {
  final VoidCallback onNext;

  const WelcomeView({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Icon(
              LucideIcons.bookOpen,
              size: 80,
              color: context.colors.plum,
            ),
            const SizedBox(height: 32),
            Text(
              'Welcome to ZapBook',
              style: context.typography.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Your private, sovereign library for reading, ingesting, and owning your books.',
              style: context.typography.bodyL.copyWith(color: context.colors.slate),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            AppButton(
              label: 'Get Started',
              onTap: onNext,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}
