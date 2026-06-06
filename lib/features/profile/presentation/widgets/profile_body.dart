import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/features/profile/domain/entities/user_profile.dart';
import 'package:zapbook/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_ai_tile.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_appearance_tile.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_section.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_sign_out_tile.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_stats_row.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_tile.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_wallet_card.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_toast.dart';

class ProfileBody extends StatelessWidget {
  const ProfileBody({super.key, required this.profile});

  final UserProfile profile;

  static const String _appVersion = 'ZapBook · v0.4.0';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileWalletCard(
            profile: profile,
            onWallet: () {},
            onCopyLightning: () => _copy(
              context,
              profile.lightningAddress,
              'Lightning address copied',
            ),
          ),
          const SizedBox(height: 16),
          ProfileStatsRow(profile: profile),
          const SizedBox(height: 26),
          ProfileSection(
            label: 'Account',
            tiles: [
              const ProfileAiTile(),
              ProfileTile(
                icon: LucideIcons.shieldCheck,
                title: 'Manage keys',
                subtitle: 'Back up or export your nsec',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 26),
          ProfileSection(
            label: 'App',
            tiles: [
              ProfileTile(
                icon: LucideIcons.bell,
                title: 'Notifications',
                onTap: () {},
              ),
              const ProfileAppearanceTile(),
              const ProfileSignOutTile(),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              _appVersion,
              style: context.typography.caption.copyWith(color: colors.slate2),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context, String value, String message) async {
    await context.read<ProfileCubit>().copy(value);
    if (context.mounted) context.toast.showInfo(message);
  }
}
