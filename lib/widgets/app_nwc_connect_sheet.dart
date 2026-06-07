import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_button.dart';
import 'package:zapbook/widgets/app_input.dart';
import 'package:zapbook/widgets/app_sheet.dart';
import 'package:zapbook/widgets/app_toast.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class _AppNwcConnectSheetState extends State<AppNwcConnectSheet> {
  late final TextEditingController _controller;
  bool _connecting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _controller.text = data!.text!.trim();
    }
  }

  void _clear() => _controller.clear();

  Future<void> _connect() async {
    final uri = _controller.text.trim();
    if (uri.isEmpty) return;
    if (!uri.startsWith('nostr+walletconnect://') &&
        !uri.startsWith('bunker://')) {
      context.toast.showError('Invalid connection string', rootNavigator: true);
      return;
    }
    setState(() => _connecting = true);
    try {
      await widget.onConnect(uri);
      if (mounted) context.pop();
    } on Exception {
      if (mounted) setState(() => _connecting = false);
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
            Text(
              'Connect Wallet',
              style: context.typography.displayM.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colors.ink,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Paste your NWC connection string from Alby, Mutiny, or any Nostr Wallet Connect provider.',
              style: context.typography.bodyL.copyWith(
                color: context.colors.slate,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: AppInput(
                    controller: _controller,
                    icon: LucideIcons.link,
                    label: 'Connection string',
                    hintText: 'nostr+walletconnect://...',
                    trailing: _controller.text.isNotEmpty
                        ? BouncingInteractiveWidget(
                            onTap: _clear,
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
                _PasteButton(onTap: _paste),
              ],
            ),
            const SizedBox(height: 24),
            AppButton(
              label: _connecting ? 'Connecting…' : 'Connect',
              fullWidth: true,
              variant: AppButtonVariant.primary,
              isLoading: _connecting,
              onTap: _connecting ? null : _connect,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class AppNwcConnectSheet extends StatefulWidget {
  final Future<void> Function(String uri) onConnect;

  const AppNwcConnectSheet({super.key, required this.onConnect});

  @override
  State<AppNwcConnectSheet> createState() => _AppNwcConnectSheetState();

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function(String uri) onConnect,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppNwcConnectSheet(onConnect: onConnect),
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
