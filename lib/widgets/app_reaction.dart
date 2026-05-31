import 'package:flutter/material.dart';
import 'package:zapbook/theme/app_radii.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';
import 'package:intl/intl.dart';

class AppReaction extends StatelessWidget {
  final String emoji;
  final String label;
  final int? sats;
  final bool active;
  final bool big;
  final VoidCallback? onTap;

  const AppReaction({
    super.key,
    required this.emoji,
    required this.label,
    this.sats,
    this.active = false,
    this.big = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final semanticColors = context.colors;
    final typography = context.typography;
    final formatCurrency = NumberFormat.decimalPattern();

    final accentColor = active
        ? semanticColors.bitcoin
        : semanticColors.bitcoin;

    Widget content = Container(
      padding: big
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 16)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
      decoration: BoxDecoration(
        color: active ? semanticColors.bitcoinTint : semanticColors.paper2,
        borderRadius: AppRadii.br18,
        border: Border.all(
          color: active ? semanticColors.bitcoinTint2 : semanticColors.hairline,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(emoji, style: TextStyle(fontSize: big ? 32 : 27, height: 1.0)),
          const SizedBox(height: 7),
          Text(
            label,
            style: typography.body.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              height: 1.0,
              color: semanticColors.slate,
            ),
          ),
          if (sats != null) ...[
            const SizedBox(height: 7),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(LucideIcons.zap, size: 11, color: accentColor),
                const SizedBox(width: 3),
                Text(
                  formatCurrency.format(sats),
                  style: typography.mono.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.0,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return BouncingInteractiveWidget(
        onTap: onTap,
        scaleFactor: 0.95,
        child: content,
      );
    }
    return content;
  }
}
