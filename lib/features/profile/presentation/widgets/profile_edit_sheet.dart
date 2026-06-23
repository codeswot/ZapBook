import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/core/domain/validators.dart';
import 'package:zapbook/core/services/profile_meta_generator.dart';
import 'package:zapbook/features/profile/domain/entities/user_profile.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_button.dart';
import 'package:zapbook/widgets/app_input.dart';
import 'package:zapbook/widgets/app_profile_avatar.dart';
import 'package:zapbook/widgets/app_sheet.dart';
import 'package:zapbook/widgets/app_toast.dart';
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
    _lud16Controller = TextEditingController(
      text: widget.profile.lightningAddress,
    )..addListener(() => setState(() {}));
    _picture = widget.profile.picture;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lud16Controller.dispose();
    super.dispose();
  }

  void _cycleAll() {
    final meta = ProfileMetaGenerator.generate();
    setState(() => _picture = meta.avatar);
  }

  Future<void> _pickImage() async {
    final url = await widget.pickImage();
    if (url.isNotEmpty && mounted) {
      setState(() => _picture = url);
    }
  }

  Future<void> _pasteLud16() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _lud16Controller.text = data!.text!.trim();
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final lud16 = _lud16Controller.text.trim();

    final nameError = Validators.displayName(name);
    if (nameError != null) {
      context.toast.showError(nameError);
      return;
    }
    final lud16Error = Validators.lud16(lud16);
    if (lud16Error != null) {
      context.toast.showError(lud16Error);
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.onSave(displayName: name, lud16: lud16, picture: _picture);
      if (mounted) context.pop();
    } on Exception {
      if (mounted) setState(() => _saving = false);
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Edit Profile',
                    style: context.typography.displayM.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.colors.ink,
                    ),
                  ),
                ),
                BouncingInteractiveWidget(
                  onTap: _cycleAll,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.colors.nostrTint,
                      borderRadius: AppRadii.br12,
                    ),
                    child: Icon(
                      LucideIcons.shuffle,
                      size: 18,
                      color: context.colors.nostr,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Center(
              child: Stack(
                children: [
                  AppProfileAvatar(url: _picture, size: 96),
                  Positioned(
                    bottom: 0,
                    right: -4,
                    child: BouncingInteractiveWidget(
                      onTap: _pickImage,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: context.colors.nostr,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.colors.paper,
                            width: 2.5,
                          ),
                        ),
                        child: Icon(
                          LucideIcons.camera,
                          size: 15,
                          color: context.colors.paper,
                        ),
                      ),
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
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: AppInput(
                    controller: _lud16Controller,
                    icon: LucideIcons.zap,
                    label: 'Lightning Address (lud16)',
                    hintText: 'you@getalby.com',
                    trailing: _lud16Controller.text.isNotEmpty
                        ? BouncingInteractiveWidget(
                            onTap: () => _lud16Controller.clear(),
                            child: Icon(
                              LucideIcons.x,
                              size: 18,
                              color: context.colors.slate,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                _PasteButton(onTap: _pasteLud16),
              ],
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
  })
  onSave;
  final Future<String> Function() pickImage;

  const ProfileEditSheet({
    super.key,
    required this.profile,
    required this.onSave,
    required this.pickImage,
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
    })
    onSave,
    required Future<String> Function() pickImage,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProfileEditSheet(
        profile: profile,
        onSave: onSave,
        pickImage: pickImage,
      ),
    );
  }
}

class _PasteButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PasteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BouncingInteractiveWidget(
      onTap: onTap,
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: context.colors.paper2,
          borderRadius: AppRadii.br10,
          border: Border.all(color: context.colors.hairline),
        ),
        child: Icon(LucideIcons.clipboard, color: context.colors.slate),
      ),
    );
  }
}
