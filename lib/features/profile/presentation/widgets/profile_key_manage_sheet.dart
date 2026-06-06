import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/core/extensions/string_extension.dart';
import 'package:zapbook/core/services/clipboard_service.dart';
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
  final _clipboard = ClipboardService();
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
            _KeyBlock(
              label: 'Public Key (npub)',
              displayValue: widget.npub.toNpubReadable(),
              rawValue: widget.npub,
              clipboard: _clipboard,
            ),
            const SizedBox(height: 12),
            _KeyBlock(
              label: 'Secret Key (nsec)',
              displayValue: _nsecRevealed ? widget.nsec : _masked,
              rawValue: widget.nsec,
              clipboard: _clipboard,
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

  String get _masked => 'nsec1•••••••••••••••••••••••••••••••••••••••••••';
}

class _KeyBlock extends StatelessWidget {
  final String label;
  final String displayValue;
  final String rawValue;
  final ClipboardService clipboard;

  const _KeyBlock({
    required this.label,
    required this.displayValue,
    required this.rawValue,
    required this.clipboard,
  });

  @override
  Widget build(BuildContext context) {
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
          onTap: () async {
            await clipboard.copy(rawValue);
            if (context.mounted) {
              context.toast.showSuccess('$label copied');
            }
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
                    displayValue,
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
