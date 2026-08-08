import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zapbook/core/presentation/bloc/clipboard/clipboard_cubit.dart';
import 'package:zapbook/core/identity/bunker_signer_source.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/core/presentation/widgets/app_button.dart';
import 'package:zapbook/core/presentation/widgets/app_input.dart';
import 'package:zapbook/core/presentation/widgets/app_method_tile.dart';
import 'package:zapbook/core/presentation/widgets/app_paste_button.dart';
import 'package:zapbook/core/presentation/widgets/app_qr_code.dart';
import 'package:zapbook/core/presentation/widgets/app_scan_button.dart';
import 'package:zapbook/core/presentation/widgets/app_sheet.dart';
import 'package:zapbook/core/presentation/widgets/app_toast.dart';
import 'package:zapbook/core/presentation/widgets/bouncing_interactive_widget.dart';

enum _Phase { main, bunker, nostrConnect }

class ExternalSignerMethodSheet extends StatefulWidget {
  const ExternalSignerMethodSheet({
    super.key,
    required this.showSignerApp,
    required this.onSignerApp,
    required this.onBunker,
    required this.onStartNostrConnect,
    required this.onNostrConnect,
  });

  final bool showSignerApp;
  final Future<String?> Function() onSignerApp;
  final Future<String?> Function(String bunkerUrl) onBunker;
  final NostrConnectSession Function() onStartNostrConnect;
  final Future<String?> Function(NostrConnectSession session, {void Function()? onContact}) onNostrConnect;

  static Future<bool?> show(
    BuildContext context, {
    required bool showSignerApp,
    required Future<String?> Function() onSignerApp,
    required Future<String?> Function(String bunkerUrl) onBunker,
    required NostrConnectSession Function() onStartNostrConnect,
    required Future<String?> Function(NostrConnectSession session, {void Function()? onContact})
    onNostrConnect,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: context.colors.transparent,
      builder: (_) => ExternalSignerMethodSheet(
        showSignerApp: showSignerApp,
        onSignerApp: onSignerApp,
        onBunker: onBunker,
        onStartNostrConnect: onStartNostrConnect,
        onNostrConnect: onNostrConnect,
      ),
    );
  }

  @override
  State<ExternalSignerMethodSheet> createState() =>
      _ExternalSignerMethodSheetState();
}

class _ExternalSignerMethodSheetState extends State<ExternalSignerMethodSheet> {
  final _bunkerController = TextEditingController();
  _Phase _phase = _Phase.main;
  bool _busy = false;
  NostrConnectSession? _nostrConnectSession;
  bool _contacted = false;

  @override
  void dispose() {
    _bunkerController.dispose();
    super.dispose();
  }

  void _handleBunkerInput(String text) {
    final url = text.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('bunker://')) {
      context.toast.showError(
        'Invalid bunker connection link',
        rootNavigator: true,
      );
      return;
    }
    _bunkerController.text = url;
    setState(() {});
  }

  Future<void> _runSignerApp() async {
    setState(() {
      _busy = true;
    });
    final error = await widget.onSignerApp();
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    context.toast.showError(error, rootNavigator: true);
    setState(() {
      _busy = false;
    });
  }

  Future<void> _runBunker() async {
    final url = _bunkerController.text.trim();
    if (url.isEmpty) {
      context.toast.showError(
        'Paste a bunker:// connection link',
        rootNavigator: true,
      );
      return;
    }
    if (!url.startsWith('bunker://')) {
      context.toast.showError(
        'Invalid bunker connection link',
        rootNavigator: true,
      );
      return;
    }
    setState(() {
      _busy = true;
    });
    final error = await widget.onBunker(url);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    context.toast.showError(error, rootNavigator: true);
    setState(() {
      _busy = false;
    });
  }

  Future<void> _runNostrConnect() async {
    setState(() {
      _busy = true;
    });
    try {
      _nostrConnectSession = widget.onStartNostrConnect();
      setState(() {
        _phase = _Phase.nostrConnect;
        _busy = false;
        _contacted = false;
      });
      final error = await widget.onNostrConnect(
        _nostrConnectSession!,
        onContact: () {
          if (mounted) {
            setState(() {
              _busy = true;
              _contacted = true;
            });
          }
        },
      );
      if (!mounted) return;
      if (error == null) {
        Navigator.of(context).pop(true);
      } else {
        context.toast.showError(error, rootNavigator: true);
        setState(() {
          _phase = _Phase.main;
          _nostrConnectSession = null;
        });
      }
    } catch (e) {
      if (mounted) {
        context.toast.showError(e.toString(), rootNavigator: true);
        setState(() {
          _busy = false;
          _phase = _Phase.main;
          _nostrConnectSession = null;
        });
      }
    }
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
                if (_phase != _Phase.main)
                  BouncingInteractiveWidget(
                    onTap: () => setState(() {
                      _phase = _Phase.main;
                      _nostrConnectSession = null;
                    }),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Icon(LucideIcons.arrowLeft, color: colors.ink),
                    ),
                  ),
                Expanded(
                  child: Text(
                    switch (_phase) {
                      _Phase.bunker => 'Remote signer',
                      _Phase.nostrConnect => 'Scan with Signer',
                      _Phase.main => 'Connect a signer',
                    },
                    style: typography.displayM.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(switch (_phase) {
              _Phase.bunker =>
                'Paste the bunker link from your remote signer (nsecbunker, nsec.app, Amber…).',
              _Phase.nostrConnect =>
                'Scan this QR code with a remote signer to approve the connection.',
              _Phase.main => 'Sign without giving ZapBook your secret key.',
            }, style: typography.body.copyWith(color: colors.slate)),
            const SizedBox(height: 18),
            if (_phase == _Phase.bunker) ...[
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
                  const SizedBox(width: 8),
                  AppQrScanButton(
                    onScan: _handleBunkerInput,
                    title: 'Scan Connection',
                    instructions: 'Scan a bunker:// QR code',
                  ),
                  const SizedBox(width: 8),
                  AppPasteButton(onPaste: _handleBunkerInput),
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
            ] else if (_phase == _Phase.nostrConnect &&
                _nostrConnectSession != null) ...[
              AppQrCode(data: _nostrConnectSession?.uri ?? ''),
              const SizedBox(height: 16),
              AppButton(
                label: 'Copy Link',
                fullWidth: true,
                variant: AppButtonVariant.ghost,
                iconRight: LucideIcons.copy,
                onTap: () async {
                  await context.read<ClipboardCubit>().copy(
                    _nostrConnectSession!.uri,
                  );
                  if (context.mounted) {
                    context.toast.showInfo('Link copied to clipboard');
                  }
                },
              ),
              const SizedBox(height: 12),
              if (_contacted) const Center(child: CircularProgressIndicator()),
            ] else ...[
              if (widget.showSignerApp)
                AppMethodTile(
                  icon: LucideIcons.shieldCheck,
                  title: 'Signer app',
                  subtitle: 'Amber on this device · NIP-55',
                  busy: _busy,
                  onTap: _busy ? null : _runSignerApp,
                ),
              if (widget.showSignerApp) const SizedBox(height: 10),
              AppMethodTile(
                icon: LucideIcons.qrCode,
                title: 'Scan with Signer',
                subtitle: 'Show a QR code for your signer to scan',
                busy: _busy && _phase == _Phase.nostrConnect,
                onTap: _busy ? null : _runNostrConnect,
              ),
              const SizedBox(height: 10),
              AppMethodTile(
                icon: LucideIcons.radio,
                title: 'Remote signer',
                subtitle: 'Paste a bunker link · NIP-46',
                busy: false,
                onTap: _busy
                    ? null
                    : () => setState(() {
                        _phase = _Phase.bunker;
                      }),
              ),
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
