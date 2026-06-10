import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_button.dart';
import 'package:zapbook/widgets/app_sheet.dart';

class ZapNudgeSheet {
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final colors = sheetContext.colors;
        final typography = sheetContext.typography;
        return AppSheet(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.bitcoin.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.zap, color: colors.bitcoin, size: 26),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: typography.h3.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: typography.bodyS.copyWith(color: colors.slate),
              ),
              const SizedBox(height: 22),
              if (actionLabel != null)
                AppButton(
                  label: actionLabel,
                  fullWidth: true,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onAction?.call();
                  },
                ),
              if (actionLabel != null) const SizedBox(height: 10),
              AppButton(
                label: 'Got it',
                fullWidth: true,
                variant: AppButtonVariant.ghost,
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        );
      },
    );
  }
}
