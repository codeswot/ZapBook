import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/core/extensions/string_extension.dart';
import 'package:zapbook/features/circles/presentation/bloc/share_circle_cubit.dart';
import 'package:zapbook/features/circles/presentation/bloc/share_circle_state.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/core/presentation/widgets/app_button.dart';
import 'package:zapbook/core/presentation/widgets/app_chip.dart';
import 'package:zapbook/core/presentation/widgets/app_fade_overlay.dart';
import 'package:zapbook/core/presentation/widgets/app_input.dart';
import 'package:zapbook/core/presentation/widgets/app_loading_list.dart';
import 'package:zapbook/core/presentation/widgets/app_paste_button.dart';
import 'package:zapbook/core/presentation/widgets/app_profile_avatar.dart';
import 'package:zapbook/core/presentation/widgets/app_row.dart';
import 'package:zapbook/core/presentation/widgets/app_sheet.dart';
import 'package:zapbook/core/presentation/widgets/app_toast.dart';
import 'package:zapbook/core/presentation/widgets/bouncing_interactive_widget.dart';

class ShareCircleSheet extends StatelessWidget {
  const ShareCircleSheet({super.key, required this.book});

  final CircleBook book;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ShareCircleCubit>()..load(book.id),
      child: _Body(book: book),
    );
  }

  static Future<void> show(BuildContext context, CircleBook book) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: context.colors.transparent,
      builder: (_) => ShareCircleSheet(book: book),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.book});
  final CircleBook book;

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

  String? _validateNpub(String text, ShareCircleState state) {
    final npub = text.trim();
    if (npub.isEmpty) return null;
    if (!npub.startsWith('npub1')) return null;
    if (!context.read<ShareCircleCubit>().isValidNpub(npub)) {
      return 'Not a valid npub';
    }
    if (state is ShareCircleLoaded && state.isExistingMember(npub)) {
      return 'Already a member';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShareCircleCubit, ShareCircleState>(
      builder: (context, state) {
        final colors = context.colors;
        final typography = context.typography;
        final cubit = context.read<ShareCircleCubit>();
        final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

        final friends = state is ShareCircleLoaded
            ? state.friends
            : state is ShareCircleBusy
            ? state.friends
            : <Contact>[];
        final selectedNpubs = state is ShareCircleLoaded
            ? state.selectedNpubs
            : state is ShareCircleBusy
            ? state.selectedNpubs
            : <String>[];
        final isLoading = state is ShareCircleLoading;
        final isAdding = state is ShareCircleBusy && state.adding;
        final isSharing = state is ShareCircleBusy && state.sharing;
        final error = _validateNpub(_npubController.text, state);

        String labelFor(String npub) {
          for (final c in friends) {
            if (c.npub == npub) return c.label;
          }
          return npub.toNpubShort();
        }

        bool isExistingMember(String npub) {
          if (state is ShareCircleLoaded) return state.isExistingMember(npub);
          if (state is ShareCircleBusy) return state.isExistingMember(npub);
          return false;
        }

        final query = _npubController.text.trim().toLowerCase();
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Share to circle',
                    style: context.typography.displayM.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.colors.ink,
                    ),
                  ),
                  if (!isKeyboardOpen) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Pick friends or paste an npub. They join "${widget.book.title}" and it appears in their library.',
                      style: typography.body.copyWith(color: colors.slate),
                    ),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      error,
                      style: typography.bodyS.copyWith(color: colors.tomato),
                    ),
                  ],
                  if (!isKeyboardOpen && selectedNpubs.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 40,
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(right: 52),
                            itemCount: selectedNpubs.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final npub = selectedNpubs[index];
                              if (!npub.isNpub) return const SizedBox.shrink();

                              return AppChip(
                                label: labelFor(npub),
                                icon: LucideIcons.x,
                                selected: true,
                                onTap: () => cubit.toggleNpub(npub),
                              );
                            },
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.paper,
                              border: Border.all(color: colors.slate),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.ink.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(-4, 0),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${selectedNpubs.length}',
                              style: typography.body.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Friends',
                    style: typography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      letterSpacing: 0.24,
                      color: colors.slate,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
              Expanded(
                flex: 1,
                child: Builder(
                  builder: (context) {
                    if (isLoading) {
                      return const SingleChildScrollView(
                        child: AppLoadingList(),
                      );
                    }
                    if (friends.isEmpty && query.isEmpty) {
                      return Text(
                        'No contacts yet. Paste an npub to add your first friend.',
                        style: typography.body.copyWith(color: colors.slate),
                      );
                    }
                    if (displayedFriends.isEmpty && query.isNotEmpty) {
                      if (isNpubInput) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'No contacts found matching "$query"'.substring(
                                0,
                                query.length > 30 ? 30 : null,
                              ) +
                              (query.length > 30 ? '...' : ''),
                          style: typography.body.copyWith(color: colors.slate),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return Stack(
                      children: [
                        ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shrinkWrap: true,
                          itemCount: displayedFriends.length,
                          itemBuilder: (context, index) {
                            final contact = displayedFriends[index];
                            final isExisting = isExistingMember(contact.npub);
                            final isSelected = selectedNpubs.contains(
                              contact.npub,
                            );

                            String getSubtitle() {
                              if (isExisting) return 'Already in circle';
                              return contact.shortNpub;
                            }

                            Widget getTrailingIcon() {
                              if (isExisting) {
                                return Icon(
                                  LucideIcons.checkCheck,
                                  size: 20,
                                  color: colors.slate2,
                                );
                              }
                              if (isSelected) {
                                return Icon(
                                  LucideIcons.checkCheck,
                                  size: 20,
                                  color: colors.mint,
                                );
                              }
                              return Icon(
                                LucideIcons.plus,
                                size: 20,
                                color: colors.slate,
                              );
                            }

                            VoidCallback? getOnTap() {
                              if (isExisting) return null;
                              return () => cubit.toggleNpub(contact.npub);
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: AppRow(
                                leading: AppProfileAvatar(
                                  url: contact.picture ?? '',
                                  size: 40,
                                ),
                                title: contact.label,
                                subtitle: getSubtitle(),
                                trailing: getTrailingIcon(),
                                onTap: getOnTap(),
                              ),
                            );
                          },
                        ),
                        AppFadeOverlay.top(color: colors.paper, height: 12),
                        AppFadeOverlay.bottom(color: colors.paper, height: 12),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: AppInput(
                      label: 'Search contacts or paste npub',
                      hintText: 'search or paste npub...',
                      icon: LucideIcons.search,
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
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            BouncingInteractiveWidget(
                              onTap: (error != null || !isNpubInput)
                                  ? null
                                  : () {
                                      cubit.addNpub(
                                        _npubController.text.trim(),
                                      );
                                      _npubController.clear();
                                      setState(() {});
                                    },
                              child: Text(
                                'Add',
                                style: typography.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: !isNpubInput
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
              const SizedBox(height: 24),
              AppButton(
                label: selectedNpubs.isEmpty
                    ? 'Share'
                    : 'Share with ${selectedNpubs.length}',
                icon: LucideIcons.userPlus,
                variant: AppButtonVariant.purple,
                fullWidth: true,
                isLoading: isSharing,
                onTap: selectedNpubs.isEmpty || isSharing
                    ? null
                    : () {
                        final circleBookId = widget.book.id;

                        final messengerState = ScaffoldMessenger.of(context);
                        final successSnackbar = AppToast.buildSnackBar(
                          context,
                          message: 'shared successfully!',
                          type: AppToastType.success,
                        );
                        final skipSnackbar = AppToast.buildSnackBar(
                          context,
                          message: 'Shared, but some friends skipped',
                          type: AppToastType.success,
                        );
                        final errorSnackbar = AppToast.buildSnackBar(
                          context,
                          message: 'Failed to share circle. Please try again.',
                          type: AppToastType.error,
                        );

                        context.toast.showSuccess(
                          'Sharing circle in the background...',
                        );
                        Navigator.of(context).pop();

                        cubit
                            .share(circleBookId)
                            .then((skipped) {
                              messengerState.hideCurrentSnackBar();
                              if (skipped.isNotEmpty) {
                                messengerState.showSnackBar(skipSnackbar);
                              } else {
                                messengerState.showSnackBar(successSnackbar);
                              }
                            })
                            .catchError((_) {
                              messengerState.hideCurrentSnackBar();
                              messengerState.showSnackBar(errorSnackbar);
                            });
                      },
              ),
              if (!isKeyboardOpen) ...[
                const SizedBox(height: 10),
                AppButton(
                  label: 'Cancel',
                  variant: AppButtonVariant.ghost,
                  fullWidth: true,
                  onTap: () => context.pop(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
