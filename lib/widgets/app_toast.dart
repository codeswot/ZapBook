import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/theme/app_radii.dart';

enum AppToastType { success, error, warning, info, normal }

class AppToast {
  static void show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.normal,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final colors = context.colors;
    final typography = context.typography;

    IconData? icon;
    Color? iconColor;
    Color? actionColor = colors.bitcoin;

    switch (type) {
      case AppToastType.success:
        icon = LucideIcons.check;
        iconColor = colors.positive;
        break;
      case AppToastType.error:
        icon = LucideIcons.alertTriangle;
        iconColor = colors.coral;
        actionColor = colors.coral;
        break;
      case AppToastType.warning:
        icon = LucideIcons.zap;
        iconColor = colors.bitcoin;
        break;
      case AppToastType.info:
        icon = LucideIcons.info;
        iconColor = colors.sky;
        break;
      case AppToastType.normal:
        break;
    }

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colors.paper3,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.br12,
        side: BorderSide(color: colors.hairline),
      ),
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      duration: const Duration(seconds: 4),
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              message,
              style: typography.bodyS.copyWith(color: colors.ink),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                onAction();
              },
              child: Text(
                actionLabel,
                style: typography.bodyS.copyWith(
                  color: actionColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}

extension ToastBuildContextExtension on BuildContext {
  AppToastHelper get toast => AppToastHelper(this);
}

class AppToastHelper {
  const AppToastHelper(this.context);
  final BuildContext context;

  void show(
    String message, {
    AppToastType type = AppToastType.normal,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    AppToast.show(
      context,
      message: message,
      type: type,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  void showSuccess(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) => show(
    message,
    type: AppToastType.success,
    actionLabel: actionLabel,
    onAction: onAction,
  );

  void showError(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) => show(
    message,
    type: AppToastType.error,
    actionLabel: actionLabel,
    onAction: onAction,
  );

  void showWarning(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) => show(
    message,
    type: AppToastType.warning,
    actionLabel: actionLabel,
    onAction: onAction,
  );

  void showInfo(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) => show(
    message,
    type: AppToastType.info,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}
