import 'package:flutter/material.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_button.dart';
import 'package:zapbook/widgets/app_sheet.dart';
import 'package:zapbook/widgets/app_toast.dart';

class ProfileKeyPackageSheet extends StatelessWidget {
  const ProfileKeyPackageSheet({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: context.colors.transparent,
      builder: (_) => const ProfileKeyPackageSheet(),
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
          Text(
            'Rotate key package?',
            style: context.typography.displayM.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your key package lets others add you to shared books. Rotating publishes a fresh one — this can fix issues where people can\'t share with you. Old shares and circles are unaffected.',
            style: typography.bodyS.copyWith(color: colors.slate),
          ),
          const SizedBox(height: 22),
          AppButton(
            label: 'Rotate now',
            fullWidth: true,
            onTap: () async {
              final ok = await getIt<ProfileCubit>().rotateKeyPackage();
              if (context.mounted) {
                Navigator.of(context).pop(true);
                if (ok) {
                  context.toast.showSuccess(
                    'Key package rotated',
                    rootNavigator: true,
                  );
                } else {
                  context.toast.showError(
                    'Rotation failed — check your connection',
                    rootNavigator: true,
                  );
                }
              }
            },
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
