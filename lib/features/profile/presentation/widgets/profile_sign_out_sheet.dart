import 'package:flutter/material.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_button.dart';
import 'package:zapbook/widgets/app_sheet.dart';

class ProfileSignOutSheet extends StatelessWidget {
  const ProfileSignOutSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return AppSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sign out?',
            style: context.typography.displayM.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This removes your key from this device. Make sure your nsec is backed up — without it, nobody can recover your account.',
            style: typography.bodyS.copyWith(color: colors.slate),
          ),
          const SizedBox(height: 22),
          AppButton(
            label: 'Sign out',
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
