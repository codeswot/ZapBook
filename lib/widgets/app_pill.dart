import 'package:flutter/material.dart';
import 'package:zapbook/theme/app_radii.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class AppPill extends StatelessWidget {
  final String emoji;
  final String text;
  final int count;
  final VoidCallback? onTap;

  const AppPill({
    super.key,
    this.emoji = '👏',
    required this.text,
    this.count = 1,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final semanticColors = context.colors;
    final typography = context.typography;

    Widget content = Container(
      height: 52,
      padding: const EdgeInsets.only(left: 14, right: 8),
      decoration: BoxDecoration(
        color: semanticColors.mist,
        borderRadius: AppRadii.br999,
        border: Border.all(color: semanticColors.hairline2),
        boxShadow: [
          BoxShadow(
            color: semanticColors.black.withValues(alpha: 0.4),
            offset: Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22, height: 1.0)),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typography.body.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                height: 1.2,
                color: semanticColors.ink,
              ),
            ),
          ),
          if (count > 1) ...[
            const SizedBox(width: 11),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: semanticColors.bitcoinTint,
                borderRadius: AppRadii.br999,
                border: Border.all(color: semanticColors.bitcoinTint2),
              ),
              child: Text(
                '+${count - 1}',
                style: typography.mono.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  height: 1.0,
                  color: semanticColors.bitcoin2,
                ),
              ),
            ),
          ],
          const SizedBox(width: 11),
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: semanticColors.paper4,
              shape: BoxShape.circle,
            ),
            child: Transform.rotate(
              angle: -90 * 3.1415927 / 180,
              child: Icon(
                LucideIcons.chevronRight,
                size: 17,
                color: semanticColors.slate2,
              ),
            ),
          ),
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
