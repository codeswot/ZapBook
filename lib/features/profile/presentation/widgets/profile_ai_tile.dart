import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_status_pill.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_tile.dart';
import 'package:zapbook/theme/app_theme.dart';

class ProfileAiTile extends StatelessWidget {
  const ProfileAiTile({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Opacity(
      opacity: 0.5,
      child: ProfileTile(
        icon: LucideIcons.cpu,
        title: 'AI Model',
        subtitle: 'Coming soon',
        trailing: ProfileStatusPill(label: 'Off', color: colors.coral),
        onTap: () {},
      ),
    );
  }
}
