import 'package:flutter/material.dart';

import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class DonateGiftChip extends StatelessWidget {
  const DonateGiftChip({super.key, required this.active, this.onTap});

  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BouncingInteractiveWidget(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: active ? colors.bitcoinTint : colors.paper2,
          borderRadius: AppRadii.br12,
          border: Border.all(
            color: active
                ? colors.bitcoin.withValues(alpha: 0.3)
                : colors.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎁', style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 6),
            Text(
              'Gift',
              style: context.typography.bodyS.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
