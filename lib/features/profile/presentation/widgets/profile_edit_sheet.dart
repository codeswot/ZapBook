import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/services/file_picker_service.dart';
import 'package:zapbook/core/services/profile_meta_generator.dart';
import 'package:zapbook/features/profile/domain/entities/user_profile.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_button.dart';
import 'package:zapbook/widgets/app_input.dart';
import 'package:zapbook/widgets/app_profile_avatar.dart';
import 'package:zapbook/widgets/app_sheet.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class _ProfileEditSheetState extends State<ProfileEditSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _lud16Controller;
  late String _picture;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.displayName);
    _lud16Controller =
        TextEditingController(text: widget.profile.lightningAddress);
    _picture = widget.profile.picture;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lud16Controller.dispose();
    super.dispose();
  }

  void _cycleMeta() {
    final meta = ProfileMetaGenerator.generate();
    _nameController.text = meta.displayName;
    setState(() => _picture = meta.avatar);
  }

  Future<void> _pickImage() async {
    final bytes = await getIt<FilePickerService>().pickImage();
    if (bytes != null && mounted) {
      setState(
          () => _picture = 'data:image/png;base64,${base64Encode(bytes)}');
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(
        displayName: _nameController.text.trim(),
        lud16: _lud16Controller.text.trim(),
        picture: _picture,
      );
      if (mounted) Navigator.of(context).pop();
    } on Object {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: context.colors.hairline2,
                  borderRadius: AppRadii.br999,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Edit Profile',
              style: context.typography.displayM.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colors.ink,
              ),
            ),
            const SizedBox(height: 28),
            Center(
              child: Stack(
                children: [
                  AppProfileAvatar(url: _picture, size: 96),
                  Positioned(
                    bottom: 0,
                    right: -4,
                    child: Row(
                      children: [
                        BouncingInteractiveWidget(
                          onTap: _pickImage,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: context.colors.nostr,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: context.colors.paper, width: 2.5),
                            ),
                            child: Icon(LucideIcons.camera,
                                size: 15, color: context.colors.paper),
                          ),
                        ),
                        const SizedBox(width: 4),
                        BouncingInteractiveWidget(
                          onTap: _cycleMeta,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: context.colors.nostr,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: context.colors.paper, width: 2.5),
                            ),
                            child: Icon(LucideIcons.shuffle,
                                size: 15, color: context.colors.paper),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppInput(
              controller: _nameController,
              icon: LucideIcons.pencil,
              label: 'Display Name',
              hintText: 'Your reader alias',
              trailing: BouncingInteractiveWidget(
                onTap: () {
                  _nameController.text = ProfileMetaGenerator.generate().displayName;
                },
                child: Icon(LucideIcons.shuffle,
                    size: 16, color: context.colors.slate),
              ),
            ),
            const SizedBox(height: 16),
            AppInput(
              controller: _lud16Controller,
              icon: LucideIcons.zap,
              label: 'Lightning Address (lud16)',
              hintText: 'you@getalby.com',
            ),
            const SizedBox(height: 28),
            AppButton(
              label: _saving ? 'Saving…' : 'Save Changes',
              fullWidth: true,
              variant: AppButtonVariant.purple,
              isLoading: _saving,
              onTap: _saving ? null : _save,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class ProfileEditSheet extends StatefulWidget {
  final UserProfile profile;
  final Future<void> Function({
    required String displayName,
    required String lud16,
    required String picture,
  }) onSave;

  const ProfileEditSheet({
    super.key,
    required this.profile,
    required this.onSave,
  });

  @override
  State<ProfileEditSheet> createState() => _ProfileEditSheetState();

  static Future<void> show(
    BuildContext context, {
    required UserProfile profile,
    required Future<void> Function({
      required String displayName,
      required String lud16,
      required String picture,
    }) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProfileEditSheet(profile: profile, onSave: onSave),
    );
  }
}
