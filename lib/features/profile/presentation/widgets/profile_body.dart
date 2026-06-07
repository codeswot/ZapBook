import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/features/profile/domain/entities/user_profile.dart';
import 'package:zapbook/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_ai_tile.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_appearance_tile.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_donate_tile.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_friends_tile.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_section.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_sign_out_tile.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_stats_row.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_tile.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_key_manage_sheet.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_wallet_card.dart';
import 'package:zapbook/widgets/app_nwc_connect_sheet.dart';
import 'package:zapbook/widgets/app_nwc_connected_sheet.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_toast.dart';

class ProfileBody extends StatelessWidget {
  const ProfileBody({super.key, required this.profile, this.nwcWalletName});

  final UserProfile profile;
  final String? nwcWalletName;

  static const String _appVersion = '0.0.1';

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
            nwcLabel: nwcWalletName != null ? 'Connected' : null,
            onWallet: () => _onWallet(context),
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
                onTap: () async {
                  final nsec = await context.read<ProfileCubit>().readNsec();
                  if (nsec != null && context.mounted) {
                    ProfileKeyManageSheet.show(
                      context,
                      npub: profile.npub,
                      nsec: nsec,
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 26),
          ProfileSection(
            label: 'Friends',
            tiles: [const ProfileFriendsTile()],
          ),
          const SizedBox(height: 26),
          ProfileSection(
            label: 'App',
            tiles: [
              const ProfileDonateTile(),
              const ProfileAppearanceTile(),
              const ProfileSignOutTile(),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'ZapBook · v$_appVersion',
              style: context.typography.caption.copyWith(color: colors.slate2),
            ),
          ),
        ],
      ),
    );
  }

  void _onWallet(BuildContext context) {
    final cubit = context.read<ProfileCubit>();
    if (nwcWalletName != null) {
      AppNwcConnectedSheet.show(
        context,
        walletName: nwcWalletName!,
        connectionString: cubit.nwcConnectionString ?? '',
        onDisconnect: () async {
          await cubit.disconnectNwc();
          if (context.mounted) context.toast.showInfo('Wallet disconnected');
        },
      );
      return;
    }

    AppNwcConnectSheet.show(
      context,
      onConnect: (uri) async {
        try {
          await cubit.connectNwc(uri);
          if (context.mounted) context.toast.showSuccess('Wallet connected');
        } on Exception {
          if (context.mounted) {
            context.toast.showError('Connection failed. Check the string.');
          }
          rethrow;
        }
      },
    );
  }

  Future<void> _copy(BuildContext context, String value, String message) async {
    await context.read<ProfileCubit>().copy(value);
    if (context.mounted) context.toast.showInfo(message);
  }
}
