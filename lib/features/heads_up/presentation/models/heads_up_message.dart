import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_banner.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

enum HeadsUpType { info, warning, error, success }

class HeadsUpMessage extends Equatable {
  final String id;
  final Widget child;

  const HeadsUpMessage({required this.id, required this.child});

  @override
  List<Object?> get props => [id, child];

  factory HeadsUpMessage.standard({
    required String id,
    required HeadsUpType type,
    required String message,
    Widget? leading,
    Widget? trailing,
    bool dismissible = true,
    VoidCallback? onDismiss,
  }) {
    return HeadsUpMessage(
      id: id,
      child: Builder(
        builder: (context) {
          final bgColor = _getBgColor(context, type);
          final textColor = _getTextColor(context, type);
          final icon = leading ?? _getDefaultIcon(context, type);

          return AppBanner(
            backgroundColor: bgColor,
            leading: icon,
            title: Text(
              message,
              style: context.typography.bodyS.copyWith(color: textColor),
            ),
            trailing:
                trailing ??
                (dismissible
                    ? BouncingInteractiveWidget(
                        onTap: onDismiss,
                        child: Icon(
                          LucideIcons.x,
                          color: textColor.withValues(alpha: 0.6),
                          size: 20,
                        ),
                      )
                    : null),
          );
        },
      ),
    );
  }

  static Color _getBgColor(BuildContext context, HeadsUpType type) {
    switch (type) {
      case HeadsUpType.info:
        return context.colors.skyTint;
      case HeadsUpType.warning:
        return context.colors.plumTint;
      case HeadsUpType.error:
        return context.colors.coralTint;
      case HeadsUpType.success:
        return context.colors.mintTint.withValues(alpha: 0.2);
    }
  }

  static Color _getTextColor(BuildContext context, HeadsUpType type) {
    switch (type) {
      case HeadsUpType.info:
        return context.colors.sky;
      case HeadsUpType.warning:
        return context.colors.plum;
      case HeadsUpType.error:
        return context.colors.tomato;
      case HeadsUpType.success:
        return context.colors.mint2;
    }
  }

  static Widget _getDefaultIcon(BuildContext context, HeadsUpType type) {
    final color = _getTextColor(context, type);
    switch (type) {
      case HeadsUpType.info:
        return Icon(LucideIcons.info, color: color, size: 16);
      case HeadsUpType.warning:
        return Icon(LucideIcons.alertTriangle, color: color, size: 16);
      case HeadsUpType.error:
        return Icon(LucideIcons.alertCircle, color: color, size: 16);
      case HeadsUpType.success:
        return Icon(LucideIcons.checkCircle, color: color, size: 16);
    }
  }
}
