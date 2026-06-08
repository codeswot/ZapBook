import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/features/library/presentation/bloc/share_circle_cubit.dart';
import 'package:zapbook/features/library/presentation/bloc/share_circle_state.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_button.dart';
import 'package:zapbook/widgets/app_chip.dart';
import 'package:zapbook/widgets/app_input.dart';
import 'package:zapbook/widgets/app_loading_list.dart';
import 'package:zapbook/widgets/app_paste_button.dart';
import 'package:zapbook/widgets/app_profile_avatar.dart';
import 'package:zapbook/widgets/app_row.dart';
import 'package:zapbook/widgets/app_sheet.dart';
import 'package:zapbook/features/library/presentation/widgets/share_result_sheet.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class ShareCircleSheet extends StatelessWidget {
  const ShareCircleSheet({super.key, required this.book});

  final LibraryBook book;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ShareCircleCubit>()..load(book.id),
      child: _Body(book: book),
    );
  }

  static Future<void> show(BuildContext context, LibraryBook book) {
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
  final LibraryBook book;

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
    return BlocConsumer<ShareCircleCubit, ShareCircleState>(
      listener: _onStateChanged,
      builder: (context, state) {
        final colors = context.colors;
        final typography = context.typography;
        final cubit = context.read<ShareCircleCubit>();

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
          return npub;
        }

        bool isExistingMember(String npub) {
          if (state is ShareCircleLoaded) return state.isExistingMember(npub);
          if (state is ShareCircleBusy) return state.isExistingMember(npub);
          return false;
        }

        return AppSheet(
          child: SingleChildScrollView(
            child: Column(
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
                const SizedBox(height: 8),
                Text(
                  'Pick friends or paste an npub. They join "${widget.book.title}" and it appears in their library.',
                  style: typography.body.copyWith(color: colors.slate),
                ),
                const SizedBox(height: 18),
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
                                onTap:
                                    (error != null ||
                                        _npubController.text.trim().isEmpty)
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
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    error,
                    style: typography.bodyS.copyWith(color: colors.tomato),
                  ),
                ],
                if (selectedNpubs.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final npub in selectedNpubs)
                        AppChip(
                          label: labelFor(npub),
                          icon: LucideIcons.x,
                          selected: true,
                          onTap: () => cubit.toggleNpub(npub),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 22),
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
                if (isLoading)
                  const AppLoadingList()
                else if (friends.isEmpty)
                  Text(
                    'No contacts yet. Paste an npub to add your first friend.',
                    style: typography.body.copyWith(color: colors.slate),
                  )
                else
                  Column(
                    children: [
                      for (final contact in friends) ...[
                        AppRow(
                          leading: AppProfileAvatar(
                            url: contact.picture ?? '',
                            size: 40,
                          ),
                          title: contact.label,
                          subtitle: isExistingMember(contact.npub)
                              ? 'Already in circle'
                              : contact.shortNpub,
                          trailing: isExistingMember(contact.npub)
                              ? Icon(
                                  LucideIcons.checkCheck,
                                  size: 20,
                                  color: colors.slate2,
                                )
                              : selectedNpubs.contains(contact.npub)
                              ? Icon(
                                  LucideIcons.checkCheck,
                                  size: 20,
                                  color: colors.mint,
                                )
                              : Icon(
                                  LucideIcons.plus,
                                  size: 20,
                                  color: colors.slate,
                                ),
                          onTap: isExistingMember(contact.npub)
                              ? null
                              : () => cubit.toggleNpub(contact.npub),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                const SizedBox(height: 24),
                AppButton(
                  label: isSharing
                      ? 'Sharing…'
                      : selectedNpubs.isEmpty
                      ? 'Share'
                      : 'Share with ${selectedNpubs.length}',
                  icon: LucideIcons.userPlus,
                  variant: AppButtonVariant.purple,
                  fullWidth: true,
                  onTap: (isSharing || selectedNpubs.isEmpty)
                      ? null
                      : () => cubit.share(widget.book.id),
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Cancel',
                  variant: AppButtonVariant.ghost,
                  fullWidth: true,
                  onTap: () => context.pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onStateChanged(BuildContext context, ShareCircleState state) {
    if (state is ShareCircleLoaded && state.shareResult != null) {
      final result = state.shareResult!;
      context.pop();
      if (result.isNotEmpty) {
        ShareResultSheet.show(context, result, state.friends);
      }
    }
  }
}
