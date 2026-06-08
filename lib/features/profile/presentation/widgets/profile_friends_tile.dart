import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/features/profile/presentation/bloc/friends_cubit.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_tile.dart';
import 'package:zapbook/features/profile/presentation/widgets/friends_sheet.dart';

class ProfileFriendsTile extends StatelessWidget {
  const ProfileFriendsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = getIt<FriendsCubit>();
    final count = cubit.contactCount;
    return ProfileTile(
      icon: LucideIcons.users,
      title: 'Friends',
      subtitle: count == 0
          ? 'No contacts yet'
          : '$count contact${count == 1 ? '' : 's'}',
      onTap: () => FriendsSheet.show(context),
    );
  }
}
