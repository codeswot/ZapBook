import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_button.dart';

class ProfileErrorView extends StatelessWidget {
  const ProfileErrorView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      child: Column(
        children: [
          Icon(LucideIcons.triangleAlert, size: 28, color: colors.tomato),
          const SizedBox(height: 12),
          Text(
            'Could not load your profile',
            style: typography.body.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: typography.bodyS.copyWith(color: colors.slate),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Retry',
            variant: AppButtonVariant.tonal,
            size: AppButtonSize.sm,
            onTap: () => context.read<ProfileCubit>().load(),
          ),
        ],
      ),
    );
  }
}
