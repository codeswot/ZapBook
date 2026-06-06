import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_button.dart';
import 'package:zapbook/widgets/app_input.dart';
import 'package:zapbook/widgets/app_sheet.dart';

class _AppNwcConnectSheetState extends State<AppNwcConnectSheet> {
  late final TextEditingController _controller;
  bool _connecting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final uri = _controller.text.trim();
    if (uri.isEmpty) return;
    setState(() => _connecting = true);
    try {
      await widget.onConnect(uri);
      if (mounted) Navigator.of(context).pop();
    } on Object {
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
            AppInput(
              controller: _controller,
              icon: LucideIcons.link,
              label: 'Connection string',
              hintText: 'nostr+walletconnect://...',
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
