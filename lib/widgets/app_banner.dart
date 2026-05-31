import 'package:flutter/material.dart';
import 'package:zapbook/theme/app_radii.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

enum AppBannerTone { info, success, warning, error, zap }

class AppBanner extends StatelessWidget {
  final AppBannerTone tone;
  final String? title;
  final String? message;
  final Widget? action;
  final VoidCallback? onClose;

  const AppBanner({
    super.key,
    this.tone = AppBannerTone.info,
    this.title,
    this.message,
    this.action,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final semanticColors = context.colors;
    final typography = context.typography;

    Color c;
    Color tint;
    Color line;
    IconData? iconData;

    switch (tone) {
      case AppBannerTone.info:
        c = semanticColors.sky;
        tint = semanticColors.skyTint;
        line = semanticColors.sky.withValues(alpha: 0.34);
        iconData = LucideIcons.info;
        break;
      case AppBannerTone.success:
        c = semanticColors.mint;
        tint = semanticColors.mintTint;
        line = semanticColors.mint.withValues(alpha: 0.34);
        iconData = LucideIcons.checkCircle;
        break;
      case AppBannerTone.warning:
        c = semanticColors.butter;
        tint = semanticColors.butterTint;
        line = semanticColors.butter.withValues(alpha: 0.34);
        iconData = LucideIcons.alertTriangle;
        break;
      case AppBannerTone.error:
        c = semanticColors.tomato;
        tint = semanticColors.tomatoTint;
        line = semanticColors.tomato.withValues(alpha: 0.36);
        iconData = LucideIcons.xCircle;
        break;
      case AppBannerTone.zap:
        c = semanticColors.bitcoin;
        tint = semanticColors.bitcoinTint;
        line = semanticColors.bitcoinTint2;
        iconData = LucideIcons.zap;
        break;
    }

    if (tone == AppBannerTone.error) iconData = LucideIcons.x;
    if (tone == AppBannerTone.success) iconData = LucideIcons.check;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: AppRadii.br18,
        border: Border.all(color: line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: line),
            ),
            child: Icon(
              iconData,
              size: tone == AppBannerTone.zap ? 18 : 19,
              color: c,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: typography.displayM.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        height: 1.25,
                        letterSpacing: -0.01 * 15,
                        color: semanticColors.ink,
                      ),
                    ),
                  if (message != null)
                    Padding(
                      padding: EdgeInsets.only(top: title != null ? 5.0 : 0.0),
                      child: Text(
                        message!,
                        style: typography.body.copyWith(
                          fontWeight: FontWeight.w400,
                          fontSize: 13.5,
                          height: 1.5,
                          color: semanticColors.slate,
                        ),
                      ),
                    ),
                  if (action != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: action!,
                    ),
                ],
              ),
            ),
          ),
          if (onClose != null) ...[
            const SizedBox(width: 13),
            BouncingInteractiveWidget(
              onTap: onClose,
              child: Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(borderRadius: AppRadii.br8),
                child: Icon(
                  LucideIcons.x,
                  size: 16,
                  color: semanticColors.slate2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
