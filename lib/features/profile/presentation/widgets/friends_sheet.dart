import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/features/profile/presentation/bloc/friends_cubit.dart';
import 'package:zapbook/features/profile/presentation/bloc/friends_state.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/core/presentation/widgets/app_input.dart';
import 'package:zapbook/core/presentation/widgets/app_fade_overlay.dart';
import 'package:zapbook/core/presentation/widgets/app_loading_list.dart';
import 'package:zapbook/core/presentation/widgets/app_paste_button.dart';
import 'package:zapbook/core/presentation/widgets/app_sheet.dart';
import 'package:zapbook/core/presentation/widgets/app_toast.dart';
import 'package:zapbook/core/presentation/widgets/bouncing_interactive_widget.dart';
import 'package:zapbook/features/profile/presentation/widgets/friend_list_item.dart';
import 'package:zapbook/features/profile/presentation/widgets/npub_preview.dart';

class FriendsSheet extends StatelessWidget {
  const FriendsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<FriendsCubit>()..load(),
      child: const _Body(),
    );
  }

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: context.colors.transparent,
      builder: (_) => const FriendsSheet(),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _npubOrSearchController = TextEditingController();
  bool _wasAdding = false;

  @override
  void dispose() {
    _npubOrSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FriendsCubit, FriendsState>(
      listener: (context, state) {
        if (state is FriendsError) {
          context.toast.showError(state.message, rootNavigator: true);
          _wasAdding = false;
        } else if (state is FriendsBusy && state.adding) {
          _wasAdding = true;
        } else if (state is FriendsLoaded && _wasAdding) {
          _npubOrSearchController.clear();
          _wasAdding = false;
        }
      },
      builder: (context, state) {
        final colors = context.colors;
        final typography = context.typography;
        final cubit = context.read<FriendsCubit>();

        final friends = state is FriendsLoaded
            ? state.friends
            : state is FriendsBusy
            ? state.friends
            : state is FriendsError
            ? state.friends
            : <Contact>[];
        final isLoading = state is FriendsLoading;
        final busyNpub = state is FriendsBusy ? state.busyNpub : null;
        final isAdding = state is FriendsBusy && state.adding;

        final query = _npubOrSearchController.text.trim().toLowerCase();
        final isNpubInput = query.startsWith('npub1');

        var displayedFriends = friends;
        if (query.isNotEmpty) {
          displayedFriends = friends.where((f) {
            return f.label.toLowerCase().contains(query) ||
                f.npub.toLowerCase().contains(query);
          }).toList();
        }

        return AppSheet(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Friends',
                    style: context.typography.displayM.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.colors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'People you have added as contacts',
                    style: typography.body.copyWith(color: colors.slate),
                  ),
                  const SizedBox(height: 18),
                  if (isLoading)
                    const AppLoadingList(itemCount: 9)
                  else if (friends.isEmpty && query.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No contacts yet.',
                        style: typography.body.copyWith(color: colors.slate),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else if (displayedFriends.isEmpty && query.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: isNpubInput
                          ? NpubPreview(
                              npub: query,
                              onAdd: () => cubit.addNpub(query),
                              isAdding: isAdding,
                            )
                          : Text(
                              'No contacts found matching "$query"'.substring(
                                    0,
                                    query.length > 30 ? 30 : null,
                                  ) +
                                  (query.length > 30 ? '...' : ''),
                              style: typography.body.copyWith(
                                color: colors.slate,
                              ),
                              textAlign: TextAlign.center,
                            ),
                    ),
                ],
              ),
              Expanded(
                flex: 1,
                child: (!isLoading && displayedFriends.isNotEmpty)
                    ? Stack(
                        children: [
                          ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              final friend = displayedFriends[index];
                              return FriendListItem(
                                friend: friend,
                                busyNpub: busyNpub,
                                onRemove: () => cubit.remove(friend.npub),
                              );
                            },
                            itemCount: displayedFriends.length,
                          ),
                          AppFadeOverlay.top(color: colors.paper, height: 12),
                          AppFadeOverlay.bottom(
                            color: colors.paper,
                            height: 12,
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: AppInput(
                      label: 'Search contacts or paste npub',
                      hintText: 'search or paste npub...',
                      icon: LucideIcons.search,
                      controller: _npubOrSearchController,
                      onChanged: (_) => setState(() {}),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_npubOrSearchController.text.isNotEmpty)
                            BouncingInteractiveWidget(
                              onTap: () {
                                _npubOrSearchController.clear();
                                setState(() {});
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Icon(
                                  LucideIcons.x,
                                  size: 16,
                                  color: colors.slate2,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  AppPasteButton(
                    onPaste: (value) {
                      _npubOrSearchController.text = value;
                      setState(() {});
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
