import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/core/extensions/string_extension.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_button.dart';
import 'package:zapbook/widgets/app_sheet.dart';
import 'package:zapbook/widgets/app_toast.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class ProfileKeyManageSheet extends StatefulWidget {
  final String npub;
  final String nsec;

  const ProfileKeyManageSheet({
    super.key,
    required this.npub,
    required this.nsec,
  });

  @override
  State<ProfileKeyManageSheet> createState() => _ProfileKeyManageSheetState();

  static Future<void> show(
    BuildContext context, {
    required String npub,
    required String nsec,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProfileKeyManageSheet(npub: npub, nsec: nsec),
    );
  }
}

class _ProfileKeyManageSheetState extends State<ProfileKeyManageSheet> {
  bool _nsecRevealed = false;

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Manage Keys',
              style: context.typography.displayM.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Never share your secret key with anyone.',
              style: context.typography.bodyL.copyWith(
                color: context.colors.slate,
              ),
            ),
            const SizedBox(height: 20),
            _keyBlock(context, 'Public Key', widget.npub.toNpubReadable()),
            const SizedBox(height: 12),
            _keyBlock(
              context,
              'Secret Key (nsec)',
              _nsecRevealed ? widget.nsec : _masked(widget.nsec),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: _nsecRevealed ? 'Hide secret key' : 'Reveal secret key',
              fullWidth: true,
              variant: AppButtonVariant.tonal,
              icon: _nsecRevealed ? LucideIcons.eyeOff : LucideIcons.eye,
              onTap: () => setState(() => _nsecRevealed = !_nsecRevealed),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _masked(String nsec) =>
      'nsec1•••••••••••••••••••••••••••••••••••••••••••';

  Widget _keyBlock(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.typography.bodyS.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colors.slate,
          ),
        ),
        const SizedBox(height: 6),
        BouncingInteractiveWidget(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            context.toast.showSuccess('$label copied');
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colors.paper2,
              borderRadius: AppRadii.br10,
              border: Border.all(color: context.colors.hairline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: context.typography.mono.copyWith(
                      fontSize: 12,
                      color: context.colors.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(LucideIcons.copy, size: 15, color: context.colors.slate),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
