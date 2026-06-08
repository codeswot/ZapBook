import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/features/profile/presentation/widgets/profile_key_package_sheet.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_tile.dart';

class ProfileKeyPackageTile extends StatelessWidget {
  const ProfileKeyPackageTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileTile(
      icon: LucideIcons.refreshCw,
      title: 'Rotate key package',
      subtitle: 'Fix sharing issues with your circle',
      onTap: () => ProfileKeyPackageSheet.show(context),
    );
  }
}
