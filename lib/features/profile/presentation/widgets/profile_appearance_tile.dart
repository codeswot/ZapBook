import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/core/theme/theme_cubit.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_tile.dart';

class ProfileAppearanceTile extends StatelessWidget {
  const ProfileAppearanceTile({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeCubit>().state;

    return ProfileTile(
      icon: LucideIcons.moon,
      title: 'Appearance',
      subtitle: _label(mode),
      onTap: () => context.read<ThemeCubit>().toggle(),
    );
  }

  String _label(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.system:
        return 'System';
    }
  }
}
