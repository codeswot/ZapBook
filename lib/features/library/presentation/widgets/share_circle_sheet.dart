import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/contact_service.dart';
import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/features/library/domain/usecases/share_book_with.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_button.dart';
import 'package:zapbook/widgets/app_chip.dart';
import 'package:zapbook/widgets/app_input.dart';
import 'package:zapbook/widgets/app_profile_avatar.dart';
import 'package:zapbook/widgets/app_row.dart';
import 'package:zapbook/widgets/app_sheet.dart';
import 'package:zapbook/widgets/app_toast.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class ShareCircleSheet extends StatefulWidget {
  const ShareCircleSheet({super.key, required this.book});

  final LibraryBook book;

  static Future<void> show(BuildContext context, LibraryBook book) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: context.colors.transparent,
      builder: (_) => ShareCircleSheet(book: book),
    );
  }

  @override
  State<ShareCircleSheet> createState() => _ShareCircleSheetState();
}

class _ShareCircleSheetState extends State<ShareCircleSheet> {
  final _contacts = getIt<ContactService>();
  final _npubController = TextEditingController();

  final Map<String, Contact> _known = {};
  final List<String> _selected = [];
  List<Contact> _friends = const [];
  bool _loadingFriends = true;
  bool _addingNpub = false;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _npubController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    final friends = await _contacts.friends();
    final myNpub = await getIt<IdentityLocalDataSource>().readNpub();
    if (!mounted) return;
    setState(() {
      _friends = friends.where((c) => c.npub != myNpub).toList();
      for (final contact in _friends) {
        _known[contact.npub] = contact;
      }
      _loadingFriends = false;
    });
  }

  Future<void> _addPasted() async {
    final npub = _npubController.text.trim();
    if (npub.isEmpty || _addingNpub) return;
    if (!_contacts.isValidNpub(npub)) {
      _snack('That is not a valid npub');
      return;
    }
    final myNpub = await getIt<IdentityLocalDataSource>().readNpub();
    if (npub == myNpub) {
      _snack('That is your own npub');
      return;
    }
    if (_known.containsKey(npub)) {
      _npubController.clear();
      _select(npub);
      return;
    }

    setState(() => _addingNpub = true);
    try {
      final contact = await _contacts.add(npub);
      if (!mounted) return;
      setState(() {
        _known[npub] = contact;
        if (_friends.every((c) => c.npub != npub)) {
          _friends = [contact, ..._friends];
        }
        if (!_selected.contains(npub)) _selected.add(npub);
        _npubController.clear();
        _addingNpub = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _addingNpub = false);
      _snack('Could not add: $error');
    }
  }

  void _select(String npub) {
    if (_selected.contains(npub)) return;
    setState(() => _selected.add(npub));
  }

  void _toggle(String npub) {
    setState(() {
      if (_selected.contains(npub)) {
        _selected.remove(npub);
      } else {
        _selected.add(npub);
      }
    });
  }

  Future<void> _share() async {
    if (_selected.isEmpty || _sharing) return;
    setState(() => _sharing = true);
    try {
      await getIt<ShareBookWith>()(
        widget.book.id,
        List<String>.from(_selected),
      );
      if (!mounted) return;
      context.pop();
      _snack('Shared with ${_selected.length}');
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _sharing = false);
      _snack('Could not share: $error');
    }
  }

  void _snack(String message) {
    context.toast.showInfo(message, rootNavigator: true);
  }

  String _labelFor(String npub) => _known[npub]?.label ?? npub;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return AppSheet(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Share to circle', style: typography.h3),
            const SizedBox(height: 8),
            Text(
              'Pick friends or paste an npub. They join “${widget.book.title}” '
              'and it appears in their library.',
              style: typography.body.copyWith(color: colors.slate),
            ),
            const SizedBox(height: 18),
            AppInput(
              label: 'Add by npub',
              hintText: 'npub1…',
              icon: LucideIcons.atSign,
              controller: _npubController,
              onChanged: (_) => setState(() {}),
              trailing: _addingNpub
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : BouncingInteractiveWidget(
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
            ),
            if (_selected.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final npub in _selected)
                    AppChip(
                      label: _labelFor(npub),
                      icon: LucideIcons.x,
                      selected: true,
                      onTap: () => _toggle(npub),
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
            _friendsList(),
            const SizedBox(height: 24),
            AppButton(
              label: _sharing
                  ? 'Sharing…'
                  : _selected.isEmpty
                  ? 'Share'
                  : 'Share with ${_selected.length}',
              icon: LucideIcons.userPlus,
              variant: AppButtonVariant.purple,
              fullWidth: true,
              onTap: (_sharing || _selected.isEmpty) ? null : _share,
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
  }

  Widget _friendsList() {
    final colors = context.colors;
    if (_loadingFriends) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_friends.isEmpty) {
      return Text(
        'No contacts yet. Paste an npub to add your first friend.',
        style: context.typography.body.copyWith(color: colors.slate),
      );
    }
    return Column(
      children: [
        for (final contact in _friends) ...[
          AppRow(
            leading: AppProfileAvatar(url: contact.picture ?? '', size: 40),
            title: contact.label,
            subtitle: contact.shortNpub,
            trailing: _selected.contains(contact.npub)
                ? Icon(LucideIcons.checkCheck, size: 20, color: colors.mint)
                : Icon(LucideIcons.plus, size: 20, color: colors.slate),
            onTap: () => _toggle(contact.npub),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
