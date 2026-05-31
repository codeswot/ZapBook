import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_button.dart';

class NostrSetupView extends StatelessWidget {
  final VoidCallback onNext;

  const NostrSetupView({super.key, required this.onNext});

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
              LucideIcons.key,
              size: 80,
              color: context.colors.bitcoin,
            ),
            const SizedBox(height: 32),
            Text(
              'Connect Nostr',
              style: context.typography.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'ZapBook uses Nostr for decentralised syncing, social highlights, and book reviews. Your identity stays yours.',
              style: context.typography.bodyL.copyWith(color: context.colors.slate),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            AppButton(
              label: 'Import nsec',
              icon: LucideIcons.keyRound,
              fullWidth: true,
              onTap: onNext,
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Create New Account',
              icon: LucideIcons.userPlus,
              variant: AppButtonVariant.ghost,
              fullWidth: true,
              onTap: onNext,
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Login with Amber',
              icon: LucideIcons.smartphone,
              variant: AppButtonVariant.ghost,
              fullWidth: true,
              onTap: onNext,
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
