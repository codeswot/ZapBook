import 'package:flutter/material.dart';
import 'package:zapbook/theme/app_radii.dart';

import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

enum AppChipTone { info, success, warning, error, zap }

class AppChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final AppChipTone? tone;
  final bool selected;
  final VoidCallback? onTap;

  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.tone,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final semanticColors = context.colors;
    final typography = context.typography;

    Color c;
    Color tint;
    Color line;

    switch (tone) {
      case AppChipTone.info:
        c = semanticColors.sky;
        tint = semanticColors.skyTint;
        line = semanticColors.sky.withValues(alpha: 0.34);
        break;
      case AppChipTone.success:
        c = semanticColors.mint;
        tint = semanticColors.mintTint;
        line = semanticColors.mint.withValues(alpha: 0.34);
        break;
      case AppChipTone.warning:
        c = semanticColors.butter;
        tint = semanticColors.butterTint;
        line = semanticColors.butter.withValues(alpha: 0.34);
        break;
      case AppChipTone.error:
        c = semanticColors.tomato;
        tint = semanticColors.tomatoTint;
        line = semanticColors.tomato.withValues(alpha: 0.36);
        break;
      case AppChipTone.zap:
      default:
        c = semanticColors.bitcoin;
        tint = semanticColors.bitcoinTint;
        line = semanticColors.bitcoinTint2;
        break;
    }

    Color defaultColor = semanticColors.slate;
    Color defaultBg = semanticColors.paper2;
    Color defaultBorder = semanticColors.ink.withValues(alpha: 0.09);

    Color bgColor = selected ? tint : defaultBg;
    Color borderColor = selected ? line : defaultBorder;
    Color fgColor = selected
        ? (tone != null ? c : semanticColors.bitcoinSoft)
        : defaultColor;

    final textStyle = typography.body.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 13,
      height: 1.0,
      color: fgColor,
    );

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: fgColor),
          const SizedBox(width: 7),
        ],
        Text(label, style: textStyle),
      ],
    );

    Widget container = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadii.br999,
        border: Border.all(color: borderColor),
      ),
      child: content,
    );

    if (onTap != null) {
      return BouncingInteractiveWidget(
        onTap: onTap,
        scaleFactor: 0.98,
        child: container,
      );
    }
    return container;
  }
}
