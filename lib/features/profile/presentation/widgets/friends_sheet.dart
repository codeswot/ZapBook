import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/features/profile/presentation/bloc/friends_cubit.dart';
import 'package:zapbook/features/profile/presentation/bloc/friends_state.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_input.dart';
import 'package:zapbook/widgets/app_loading_list.dart';
import 'package:zapbook/widgets/app_paste_button.dart';
import 'package:zapbook/widgets/app_profile_avatar.dart';
import 'package:zapbook/widgets/app_sheet.dart';
import 'package:zapbook/widgets/app_toast.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class FriendsSheet extends StatelessWidget {
  const FriendsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<FriendsCubit>()..load(),
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
  final _npubController = TextEditingController();

  @override
  void dispose() {
    _npubController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FriendsCubit, FriendsState>(
      listener: (context, state) {
        if (state is FriendsError) {
          context.toast.showError(state.message, rootNavigator: true);
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

        return AppSheet(
          child: SingleChildScrollView(
            child: Column(
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
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: AppInput(
                        label: 'Add by npub',
                        hintText: 'npub1…',
                        icon: LucideIcons.atSign,
                        controller: _npubController,
                        onChanged: (_) => setState(() {}),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_npubController.text.isNotEmpty)
                              BouncingInteractiveWidget(
                                onTap: () {
                                  _npubController.clear();
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
                            if (isAdding)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              BouncingInteractiveWidget(
                                onTap: _npubController.text.trim().isEmpty
                                    ? null
                                    : () => cubit.addNpub(
                                        _npubController.text.trim(),
                                      ),
                                child: Text(
                                  'Add',
                                  style: typography.body.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: _npubController.text.trim().isEmpty
                                        ? colors.slate2
                                        : colors.bitcoin,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AppPasteButton(
                      onPaste: (text) {
                        _npubController.text = text;
                        setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (isLoading)
                  const AppLoadingList()
                else if (friends.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No contacts yet. Paste an npub to add your first friend.',
                      style: typography.body.copyWith(color: colors.slate),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  for (final friend in friends) ...[
                    Row(
                      children: [
                        AppProfileAvatar(url: friend.picture ?? '', size: 36),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                friend.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: typography.bodyL.copyWith(
                                  color: colors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(text: friend.npub),
                                  );
                                  context.toast.showInfo(
                                    'npub copied',
                                    rootNavigator: true,
                                  );
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      friend.shortNpub,
                                      style: typography.bodyS.copyWith(
                                        color: colors.slate,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      LucideIcons.copy,
                                      size: 12,
                                      color: colors.slate2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (busyNpub == friend.npub)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          BouncingInteractiveWidget(
                            onTap: () => cubit.remove(friend.npub),
                            child: Icon(
                              LucideIcons.userMinus,
                              size: 20,
                              color: colors.tomato,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          ),
        );
      },
    );
  }
}
