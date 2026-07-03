import 'package:flutter/material.dart';
import 'package:zapbook/theme/app_radii.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:intl/intl.dart';

class AppSats extends StatelessWidget {
  final int amount;
  final double size;
  final Color? color;
  final Color? bg;
  final Color? border;

  const AppSats({
    super.key,
    required this.amount,
    this.size = 13.0,
    this.color,
    this.bg,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final semanticColors = context.colors;
    final typography = context.typography;
    final formatCurrency = NumberFormat.decimalPattern();

    final cColor = color ?? semanticColors.bitcoin;
    final bgColor = bg ?? semanticColors.bitcoinTint;
    final borderColor = border ?? semanticColors.bitcoinTint2;

    return Container(
      padding: const EdgeInsets.fromLTRB(7, 5, 9, 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadii.br999,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(LucideIcons.zap, size: size + 1, color: cColor),
          const SizedBox(width: 5),
          Text(
            formatCurrency.format(amount),
            style: typography.mono.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: size,
              height: 1.0,
              color: cColor,
            ),
          ),
        ],
      ),
    );
  }
}
