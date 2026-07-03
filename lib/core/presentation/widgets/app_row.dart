import 'package:flutter/material.dart';
import 'package:zapbook/theme/app_radii.dart';

import 'package:zapbook/theme/app_theme.dart';

class AppRow extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const AppRow({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final semanticColors = context.colors;
    final typography = context.typography;

    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: semanticColors.paper,
        borderRadius: AppRadii.br16,
        border: Border.all(color: semanticColors.ink.withValues(alpha: 0.09)),
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 13)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: typography.displayM.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                    height: 1.15,
                    letterSpacing: -0.01 * 15.5,
                    color: semanticColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: typography.body.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 12.5,
                      height: 1.2,
                      color: semanticColors.slate,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 13), trailing!],
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}
