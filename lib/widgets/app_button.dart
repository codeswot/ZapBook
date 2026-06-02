import 'package:flutter/material.dart';
import 'package:zapbook/theme/app_radii.dart';

import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

enum AppButtonVariant { primary, purple, tonal, ghost, outline, danger }

enum AppButtonSize { sm, md, lg }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final IconData? iconRight;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.icon,
    this.iconRight,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final semanticColors = context.colors;
    final typography = context.typography;

    double height;
    double paddingX;
    double fontSize;
    switch (size) {
      case AppButtonSize.sm:
        height = 38.0;
        paddingX = 16.0;
        fontSize = 14.0;
        break;
      case AppButtonSize.md:
        height = 48.0;
        paddingX = 22.0;
        fontSize = 15.0;
        break;
      case AppButtonSize.lg:
        height = 56.0;
        paddingX = 22.0;
        fontSize = 16.0;
        break;
    }

    Color bgColor;
    Color fgColor;
    Color borderColor;

    switch (variant) {
      case AppButtonVariant.primary:
        bgColor = semanticColors.bitcoin;
        fgColor = semanticColors.bitcoinDark;
        borderColor = semanticColors.transparent;
        break;
      case AppButtonVariant.purple:
        bgColor = semanticColors.nostr;
        fgColor = semanticColors.white;
        borderColor = semanticColors.transparent;
        break;
      case AppButtonVariant.tonal:
        bgColor = semanticColors.paper3;
        fgColor = semanticColors.ink;
        borderColor = semanticColors.ink.withValues(alpha: 0.09);
        break;
      case AppButtonVariant.ghost:
        bgColor = semanticColors.transparent;
        fgColor = semanticColors.slate;
        borderColor = semanticColors.transparent;
        break;
      case AppButtonVariant.outline:
        bgColor = semanticColors.transparent;
        fgColor = semanticColors.ink;
        borderColor = semanticColors.ink.withValues(alpha: 0.14);
        break;
      case AppButtonVariant.danger:
        bgColor = semanticColors.tomato;
        fgColor = semanticColors.white;
        borderColor = semanticColors.transparent;
        break;
    }

    if (onTap == null) {
      bgColor = bgColor.withValues(alpha: 0.5);
      fgColor = fgColor.withValues(alpha: 0.5);
      if (borderColor != semanticColors.transparent) {
        borderColor = borderColor.withValues(alpha: 0.5);
      }
    }

    final buttonTextStyle = typography.body.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: fontSize,
      height: 1.0,
      letterSpacing: 0.01 * fontSize,
      color: fgColor,
    );

    Widget content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: fontSize + 4, color: fgColor),
          const SizedBox(width: 9),
        ],
        Text(label, style: buttonTextStyle),
        if (iconRight != null) ...[
          const SizedBox(width: 9),
          Icon(iconRight, size: fontSize + 3, color: fgColor),
        ],
      ],
    );

    return BouncingInteractiveWidget(
      onTap: onTap,
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: paddingX),
        width: fullWidth ? double.infinity : null,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppRadii.br10,
          border: Border.all(color: borderColor),
        ),
        child: content,
      ),
    );
  }
}
