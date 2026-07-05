import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/features/profile/presentation/bloc/friends_cubit.dart';
import 'package:zapbook/features/profile/presentation/bloc/friends_state.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_tile.dart';
import 'package:zapbook/features/profile/presentation/widgets/friends_sheet.dart';

class ProfileFriendsTile extends StatelessWidget {
  const ProfileFriendsTile({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<FriendsCubit>()..load(),
      child: BlocBuilder<FriendsCubit, FriendsState>(
        builder: (context, state) {
          int count = 0;
          if (state is FriendsLoaded) {
            count = state.friends.length;
          } else if (state is FriendsBusy) {
            count = state.friends.length;
          } else if (state is FriendsError) {
            count = state.friends.length;
          }

          return ProfileTile(
            icon: LucideIcons.users,
            title: 'Friends',
            subtitle: count == 0
                ? 'No contacts yet'
                : '$count contact${count == 1 ? '' : 's'}',
            onTap: () => FriendsSheet.show(context),
          );
        },
      ),
    );
  }
}
