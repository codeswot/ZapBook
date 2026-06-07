import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/core/services/contact_service.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_input.dart';
import 'package:zapbook/widgets/app_loading_list.dart';
import 'package:zapbook/widgets/app_paste_button.dart';
import 'package:zapbook/widgets/app_profile_avatar.dart';
import 'package:zapbook/widgets/app_sheet.dart';
import 'package:zapbook/widgets/app_toast.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class FriendsSheet extends StatefulWidget {
  const FriendsSheet({super.key, required this.contacts});

  final ContactService contacts;

  @override
  State<FriendsSheet> createState() => _FriendsSheetState();

  static Future<void> show(
    BuildContext context, {
    required ContactService contacts,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: context.colors.transparent,
      builder: (_) => FriendsSheet(contacts: contacts),
    );
  }
}

class _FriendsSheetState extends State<FriendsSheet> {
  final _npubController = TextEditingController();
  List<Contact>? _friends;
  String? _busyNpub;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _npubController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final friends = await widget.contacts.friends();
    if (mounted) setState(() => _friends = friends);
  }

  Future<void> _addPasted() async {
    final npub = _npubController.text.trim();
    if (npub.isEmpty || _adding) return;

    if (!widget.contacts.isValidNpub(npub)) {
      if (mounted) {
        context.toast.showError('Not a valid npub', rootNavigator: true);
      }
      return;
    }

    setState(() => _adding = true);
    try {
      await widget.contacts.add(npub);
      _npubController.clear();
      await _load();
    } on ContactException catch (e) {
      if (mounted) context.toast.showError(e.message, rootNavigator: true);
    } on Object {
      if (mounted) {
        context.toast.showError('Could not add contact', rootNavigator: true);
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _remove(String npub) async {
    setState(() => _busyNpub = npub);
    try {
      await widget.contacts.remove(npub);
      await _load();
    } finally {
      if (mounted) setState(() => _busyNpub = null);
    }
  }

  void _copy(BuildContext context, String npub) {
    Clipboard.setData(ClipboardData(text: npub));
    context.toast.showInfo('npub copied', rootNavigator: true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final friends = _friends;

    return AppSheet(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Friends', style: typography.h3),
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
                        if (_adding)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          BouncingInteractiveWidget(
                            onTap: _addPasted,
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
                AppPasteButton(onPaste: () async => setState(() {})),
              ],
            ),
            const SizedBox(height: 18),
            if (friends == null)
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
                            style: typography.bodyL.copyWith(color: colors.ink),
                          ),
                          const SizedBox(height: 2),
                          GestureDetector(
                            onTap: () => _copy(context, friend.npub),
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
                    if (_busyNpub == friend.npub)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      BouncingInteractiveWidget(
                        onTap: () => _remove(friend.npub),
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
  }
}
