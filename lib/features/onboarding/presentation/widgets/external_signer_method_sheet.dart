import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/presentation/theme/app_radii.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/core/presentation/widgets/app_button.dart';
import 'package:zapbook/core/presentation/widgets/app_input.dart';
import 'package:zapbook/core/presentation/widgets/app_paste_button.dart';
import 'package:zapbook/core/presentation/widgets/app_sheet.dart';
import 'package:zapbook/core/presentation/widgets/bouncing_interactive_widget.dart';

class ExternalSignerMethodSheet extends StatefulWidget {
  const ExternalSignerMethodSheet({
    super.key,
    required this.showSignerApp,
    required this.onSignerApp,
    required this.onBunker,
  });

  final bool showSignerApp;
  final Future<String?> Function() onSignerApp;
  final Future<String?> Function(String bunkerUrl) onBunker;

  static Future<bool?> show(
    BuildContext context, {
    required bool showSignerApp,
    required Future<String?> Function() onSignerApp,
    required Future<String?> Function(String bunkerUrl) onBunker,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExternalSignerMethodSheet(
        showSignerApp: showSignerApp,
        onSignerApp: onSignerApp,
        onBunker: onBunker,
      ),
    );
  }

  @override
  State<ExternalSignerMethodSheet> createState() =>
      _ExternalSignerMethodSheetState();
}

class _ExternalSignerMethodSheetState extends State<ExternalSignerMethodSheet> {
  final _bunkerController = TextEditingController();
  bool _bunkerPhase = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _bunkerController.dispose();
    super.dispose();
  }

  Future<void> _runSignerApp() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await widget.onSignerApp();
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  Future<void> _runBunker() async {
    final url = _bunkerController.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Paste a bunker:// connection link');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await widget.onBunker(url);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
    });
  }

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
            Row(
              children: [
                if (_bunkerPhase)
                  BouncingInteractiveWidget(
                    onTap: _busy
                        ? null
                        : () => setState(() {
                            _bunkerPhase = false;
                            _error = null;
                          }),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Icon(LucideIcons.arrowLeft, color: colors.ink),
                    ),
                  ),
                Expanded(
                  child: Text(
                    _bunkerPhase ? 'Remote signer' : 'Connect a signer',
                    style: typography.displayM.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _bunkerPhase
                  ? 'Paste the bunker link from your remote signer (nsecbunker, nsec.app, Amber…).'
                  : 'Sign without giving ZapBook your secret key.',
              style: typography.body.copyWith(color: colors.slate),
            ),
            const SizedBox(height: 18),
            if (_bunkerPhase) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: AppInput(
                      label: 'Bunker link',
                      hintText: 'bunker://…',
                      icon: LucideIcons.link,
                      controller: _bunkerController,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  AppPasteButton(
                    onPaste: (text) {
                      _bunkerController.text = text;
                      setState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Connect',
                fullWidth: true,
                variant: AppButtonVariant.purple,
                isLoading: _busy,
                iconRight: _busy ? null : LucideIcons.arrowRight,
                onTap: _busy ? null : _runBunker,
              ),
            ] else ...[
              if (widget.showSignerApp)
                _MethodTile(
                  icon: LucideIcons.shieldCheck,
                  title: 'Signer app',
                  subtitle: 'Amber on this device · NIP-55',
                  busy: _busy,
                  onTap: _busy ? null : _runSignerApp,
                ),
              if (widget.showSignerApp) const SizedBox(height: 10),
              _MethodTile(
                icon: LucideIcons.radio,
                title: 'Remote signer',
                subtitle: 'Paste a bunker link · NIP-46',
                busy: false,
                onTap: _busy
                    ? null
                    : () => setState(() {
                        _bunkerPhase = true;
                        _error = null;
                      }),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(
                _error!,
                style: typography.bodyS.copyWith(color: colors.tomato),
              ),
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.busy,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return BouncingInteractiveWidget(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.paper2,
          borderRadius: AppRadii.br16,
          border: Border.all(color: colors.hairline2),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: colors.bitcoin),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: typography.bodyL.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: typography.bodyS.copyWith(color: colors.slate),
                  ),
                ],
              ),
            ),
            if (busy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(LucideIcons.chevronRight, size: 20, color: colors.slate),
          ],
        ),
      ),
    );
  }
}
