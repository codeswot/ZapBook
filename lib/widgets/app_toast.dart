import 'dart:async';

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
    bool rootNavigator = false,
  }) {
    if (rootNavigator) {
      _showOverlay(
        context,
        message: message,
        type: type,
        actionLabel: actionLabel,
        onAction: onAction,
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        _buildSnackBar(
          context,
          message: message,
          type: type,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
      );
  }

  static void _showOverlay(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.normal,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _OverlayToast(
        message: message,
        type: type,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  static SnackBar _buildSnackBar(
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
      case AppToastType.error:
        icon = LucideIcons.alertTriangle;
        iconColor = colors.coral;
        actionColor = colors.coral;
      case AppToastType.warning:
        icon = LucideIcons.zap;
        iconColor = colors.bitcoin;
      case AppToastType.info:
        icon = LucideIcons.info;
        iconColor = colors.sky;
      case AppToastType.normal:
        break;
    }

    return SnackBar(
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
  }
}

class _OverlayToast extends StatefulWidget {
  const _OverlayToast({
    required this.message,
    required this.type,
    this.actionLabel,
    this.onAction,
    required this.onDismiss,
  });

  final String message;
  final AppToastType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  @override
  State<_OverlayToast> createState() => _OverlayToastState();
}

class _OverlayToastState extends State<_OverlayToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    _timer = Timer(const Duration(seconds: 4), () => _dismiss());
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final bottom = MediaQuery.of(context).padding.bottom + 20;

    IconData? icon;
    Color? iconColor;
    Color? actionColor = colors.bitcoin;

    switch (widget.type) {
      case AppToastType.success:
        icon = LucideIcons.check;
        iconColor = colors.positive;
      case AppToastType.error:
        icon = LucideIcons.alertTriangle;
        iconColor = colors.coral;
        actionColor = colors.coral;
      case AppToastType.warning:
        icon = LucideIcons.zap;
        iconColor = colors.bitcoin;
      case AppToastType.info:
        icon = LucideIcons.info;
        iconColor = colors.sky;
      case AppToastType.normal:
        break;
    }

    return Positioned(
      left: 20,
      right: 20,
      bottom: bottom,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTap: _dismiss,
          child: Material(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: colors.paper3,
                borderRadius: AppRadii.br12,
                border: Border.all(color: colors.hairline),
                boxShadow: [
                  BoxShadow(
                    color: colors.ink.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: iconColor, size: 20),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      widget.message,
                      style: typography.bodyS.copyWith(color: colors.ink),
                    ),
                  ),
                  if (widget.actionLabel != null &&
                      widget.onAction != null) ...[
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: widget.onAction,
                      child: Text(
                        widget.actionLabel!,
                        style: typography.bodyS.copyWith(
                          color: actionColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
    bool rootNavigator = false,
  }) {
    AppToast.show(
      context,
      message: message,
      type: type,
      actionLabel: actionLabel,
      onAction: onAction,
      rootNavigator: rootNavigator,
    );
  }

  void showSuccess(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    bool rootNavigator = false,
  }) => show(
    message,
    type: AppToastType.success,
    actionLabel: actionLabel,
    onAction: onAction,
    rootNavigator: rootNavigator,
  );

  void showError(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    bool rootNavigator = false,
  }) => show(
    message,
    type: AppToastType.error,
    actionLabel: actionLabel,
    onAction: onAction,
    rootNavigator: rootNavigator,
  );

  void showWarning(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    bool rootNavigator = false,
  }) => show(
    message,
    type: AppToastType.warning,
    actionLabel: actionLabel,
    onAction: onAction,
    rootNavigator: rootNavigator,
  );

  void showInfo(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    bool rootNavigator = false,
  }) => show(
    message,
    type: AppToastType.info,
    actionLabel: actionLabel,
    onAction: onAction,
    rootNavigator: rootNavigator,
  );
}
