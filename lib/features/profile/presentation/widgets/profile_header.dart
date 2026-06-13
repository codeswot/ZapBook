import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/core/extensions/string_extension.dart';
import 'package:zapbook/features/profile/domain/entities/user_profile.dart';
import 'package:zapbook/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_icon_button.dart';
import 'package:zapbook/widgets/app_profile_avatar.dart';
import 'package:zapbook/widgets/app_shimmer.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_edit_sheet.dart';
import 'package:zapbook/widgets/app_toast.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colors.hairline)),
      ),
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) => switch (state) {
          ProfileLoaded(:final profile) => _ProfileHeaderContent(
            profile: profile,
          ),
          _ => const _ProfileHeaderPlaceholder(),
        },
      ),
    );
  }
}

class _ProfileHeaderContent extends StatelessWidget {
  const _ProfileHeaderContent({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppProfileAvatar(url: profile.picture, size: 48),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                profile.displayName,
                style: typography.h1.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: colors.ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    profile.npub.toNpubShort(),
                    style: typography.body.copyWith(
                      color: colors.slate,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  BouncingInteractiveWidget(
                    onTap: () => _copyNpub(context),
                    child: Icon(
                      LucideIcons.copy,
                      size: 14,
                      color: colors.slate,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        AppIconButton(
          onTap: () => ProfileEditSheet.show(
            context,
            profile: profile,
            pickImage: () => context.read<ProfileCubit>().pickImage(),
            onSave:
                ({required displayName, required lud16, required picture}) =>
                    context.read<ProfileCubit>().updateProfile(
                      displayName: displayName,
                      lud16: lud16,
                      picture: picture,
                    ),
          ),
          icon: LucideIcons.edit2,
          size: 20,
          color: colors.ink,
          backgroundColor: colors.paper,
        ),
      ],
    );
  }

  Future<void> _copyNpub(BuildContext context) async {
    await context.read<ProfileCubit>().copy(profile.npub);
    if (context.mounted) context.toast.showSuccess('npub copied');
  }
}

class _ProfileHeaderPlaceholder extends StatelessWidget {
  const _ProfileHeaderPlaceholder();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Row(
        children: [
          const AppShimmerBox(width: 48, height: 48, shape: BoxShape.circle),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                AppShimmerBox(width: 150, height: 16),
                SizedBox(height: 8),
                AppShimmerBox(width: 110, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 16),
          AppShimmerBox(width: 40, height: 40, borderRadius: AppRadii.br10),
        ],
      ),
    );
  }
}
