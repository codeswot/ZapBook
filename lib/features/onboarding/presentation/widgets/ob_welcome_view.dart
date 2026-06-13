import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/theme/app_radii.dart';

class ObWelcomeView extends StatelessWidget {
  const ObWelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 60),
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: context.colors.bitcoin,
            borderRadius: AppRadii.br24,
          ),
          child: Icon(
            LucideIcons.zap,
            size: 50,
            color: context.colors.bitcoinDark,
          ),
        ),
        const SizedBox(height: 34),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: "Zap",
                style: context.typography.displayM.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colors.ink,
                  fontSize: 40,
                ),
              ),
              TextSpan(
                text: "Book",
                style: context.typography.displayM.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.colors.ink,
                  fontSize: 40,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Read books together. Prove you read them. Get zapped real sats by your circle.",
            style: context.typography.bodyL.copyWith(
              color: context.colors.slate,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 48),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _WelcomeBadge(emoji: '📖', label: 'Read'),
            SizedBox(width: 18),
            _WelcomeBadge(emoji: '✓', label: 'Prove'),
            SizedBox(width: 18),
            _WelcomeBadge(emoji: '⚡', label: 'Get zapped'),
          ],
        ),
      ],
    );
  }
}

class _WelcomeBadge extends StatelessWidget {
  final String emoji;
  final String label;

  const _WelcomeBadge({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: context.colors.paper2,
            borderRadius: AppRadii.br16,
            border: Border.all(color: context.colors.hairline),
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 22)),
        ),
        const SizedBox(height: 9),
        Text(
          label,
          style: context.typography.bodyS.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colors.slate,
          ),
        ),
      ],
    );
  }
}
