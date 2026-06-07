import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/features/profile/presentation/widgets/profile_donate_sheet.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_tile.dart';
import 'package:zapbook/theme/app_theme.dart';

class ProfileDonateTile extends StatelessWidget {
  const ProfileDonateTile({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ProfileTile(
      icon: LucideIcons.zap,
      iconColor: colors.bitcoin,
      title: 'Support ZapBook',
      subtitle: 'zapbook@blink.sv',
      onTap: () => ProfileDonateSheet.show(context),
    );
  }
}
