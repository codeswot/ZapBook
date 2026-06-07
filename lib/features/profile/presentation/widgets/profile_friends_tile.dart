import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/services/contact_service.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_tile.dart';
import 'package:zapbook/features/profile/presentation/widgets/friends_sheet.dart';

class ProfileFriendsTile extends StatelessWidget {
  const ProfileFriendsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final contacts = getIt<ContactService>();
    final count = contacts.stored.length;
    return ProfileTile(
      icon: LucideIcons.users,
      title: 'Friends',
      subtitle: count == 0 ? 'No contacts yet' : '$count contact${count == 1 ? '' : 's'}',
      onTap: () => FriendsSheet.show(context, contacts: contacts),
    );
  }
}
