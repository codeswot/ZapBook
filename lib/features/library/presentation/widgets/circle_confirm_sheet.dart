import 'package:flutter/material.dart';

import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_button.dart';
import 'package:zapbook/widgets/app_sheet.dart';

class CircleConfirmSheet extends StatelessWidget {
  const CircleConfirmSheet({
    super.key,
    required this.title,
    required this.message,
    required this.action,
  });

  final String title;
  final String message;
  final String action;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      backgroundColor: context.colors.transparent,
      builder: (_) =>
          CircleConfirmSheet(title: title, message: message, action: action),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return AppSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: typography.h3),
          const SizedBox(height: 10),
          Text(message, style: typography.body.copyWith(color: colors.slate)),
          const SizedBox(height: 28),
          AppButton(
            label: action,
            variant: AppButtonVariant.danger,
            fullWidth: true,
            onTap: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: 10),
          AppButton(
            label: 'Cancel',
            variant: AppButtonVariant.ghost,
            fullWidth: true,
            onTap: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}
