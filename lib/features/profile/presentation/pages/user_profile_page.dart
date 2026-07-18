import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/extensions/string_extension.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/core/presentation/widgets/app_back_button.dart';
import 'package:zapbook/core/presentation/widgets/app_button.dart';
import 'package:zapbook/core/presentation/widgets/app_profile_avatar.dart';
import 'package:zapbook/core/presentation/widgets/app_toast.dart';
import 'package:zapbook/core/presentation/widgets/bouncing_interactive_widget.dart';
import 'package:zapbook/core/presentation/widgets/zap_nudge_sheet.dart';
import 'package:zapbook/core/presentation/widgets/zap_sheet.dart';
import 'package:zapbook/features/profile/domain/entities/user_profile.dart';
import 'package:zapbook/features/profile/presentation/bloc/user_profile_cubit.dart';
import 'package:zapbook/features/profile/presentation/bloc/user_profile_zap_cubit.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_section.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_shimmer.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_stats_row.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key, required this.npub});

  final String npub;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<UserProfileCubit>()..load(npub),
      child: const _UserProfileView(),
    );
  }
}

class _UserProfileView extends StatelessWidget {
  const _UserProfileView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
              child: Row(
                children: [
                  AppBackButton(),
                  const SizedBox(width: 12),
                  Text(
                    'Profile',
                    style: context.typography.h1.copyWith(
                      color: context.colors.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<UserProfileCubit, UserProfileState>(
                builder: (context, state) => switch (state) {
                  UserProfileLoading() => const ProfileShimmer(),
                  UserProfileError(:final message) => _UserProfileErrorView(
                    message: message,
                  ),
                  UserProfileLoaded(:final profile) => _UserProfileLoadedView(
                    profile: profile,
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserProfileLoadedView extends StatelessWidget {
  const _UserProfileLoadedView({required this.profile});

  final UserProfile profile;

  Future<void> _copyNpub(BuildContext context) async {
    await context.read<UserProfileCubit>().copy(profile.npub);
    if (context.mounted) context.toast.showSuccess('npub copied');
  }

  void _onZapTap(BuildContext context) {
    if (!profile.hasLightning) {
      ZapNudgeSheet.show(
        context,
        title: 'No lightning address',
        message:
            '${profile.displayName} hasn\'t set up a lightning address yet, so they can\'t receive zaps.',
      );
      return;
    }

    ZapSheet.show(
      context: context,
      header: Row(
        children: [
          AppProfileAvatar(url: profile.picture, size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Zap ${profile.displayName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.typography.h3.copyWith(
                color: context.colors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      onZapSelected: (gesture, amount, message) =>
          _zap(context, gesture, amount, message),
    );
  }

  Future<void> _zap(
    BuildContext context,
    ZapGesture gesture,
    int amount,
    String? message,
  ) async {
    final messenger = context.toast;
    final cubit = getIt<UserProfileZapCubit>();
    await cubit.sendZap(
      profile: profile,
      gesture: gesture,
      customSats: amount,
      comment: message,
    );

    final state = cubit.state;
    if (state is UserProfileZapSuccess) {
      messenger.showSuccess(
        'Zapping ${state.amountSats} sats to ${state.profileLabel}',
      );
    } else if (state is UserProfileZapFailure) {
      messenger.showError(state.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              const SizedBox(height: 14),
              AppProfileAvatar(url: profile.picture, size: 88),
              const SizedBox(height: 14),
              Text(
                profile.displayName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: typography.h1.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 6),
              BouncingInteractiveWidget(
                onTap: () => _copyNpub(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      profile.npub.toNpubShort(),
                      style: typography.body.copyWith(
                        color: colors.slate,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(LucideIcons.copy, size: 14, color: colors.slate),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          ProfileSection(
            label: 'Achievements',
            tiles: [ProfileStatsRow(profile: profile)],
          ),
          const SizedBox(height: 28),
          AppButton(
            label: 'Zap Profile',
            icon: LucideIcons.zap,
            fullWidth: true,
            variant: profile.hasLightning
                ? AppButtonVariant.primary
                : AppButtonVariant.ghost,
            onTap: () => _onZapTap(context),
          ),
          if (!profile.isSelf) ...[
            const SizedBox(height: 12),
            AppButton(
              label: profile.isFollow ? 'Unfollow' : 'Follow',
              icon: profile.isFollow
                  ? LucideIcons.userMinus
                  : LucideIcons.userPlus,
              fullWidth: true,
              variant: profile.isFollow
                  ? AppButtonVariant.outline
                  : AppButtonVariant.purple,
              onTap: () => context.read<UserProfileCubit>().toggleFollow(),
            ),
          ],
        ],
      ),
    );
  }
}

class _UserProfileErrorView extends StatelessWidget {
  const _UserProfileErrorView({required this.message});

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
            'Could not load profile',
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
        ],
      ),
    );
  }
}
