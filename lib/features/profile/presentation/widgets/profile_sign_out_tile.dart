import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_sign_out_dialog.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_tile.dart';
import 'package:zapbook/theme/app_theme.dart';

class ProfileSignOutTile extends StatelessWidget {
  const ProfileSignOutTile({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ProfileTile(
      icon: LucideIcons.logOut,
      title: 'Sign out',
      iconColor: colors.tomato,
      titleColor: colors.tomato,
      showChevron: false,
      onTap: () => _confirm(context),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final cubit = context.read<ProfileCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const ProfileSignOutDialog(),
    );
    if (confirmed != true) return;
    await cubit.signOut();
    if (context.mounted) context.go('/onboarding');
  }
}
