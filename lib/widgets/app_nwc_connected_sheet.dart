import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_button.dart';
import 'package:zapbook/widgets/app_sheet.dart';

class _AppNwcConnectedSheetState extends State<AppNwcConnectedSheet> {
  bool _disconnecting = false;

  Future<void> _disconnect() async {
    setState(() => _disconnecting = true);
    try {
      await widget.onDisconnect();
      if (mounted) context.pop();
    } on Exception {
      if (mounted) setState(() => _disconnecting = false);
    }
  }

  ({String pubkey, String relay}) _parse() {
    final uri = Uri.tryParse(widget.connectionString);
    final pubkey = uri?.host ?? '';
    final relay =
        uri?.queryParameters['relay'] ??
        uri?.queryParameters['relays']?.split(',').first ??
        '';
    final shortPubkey = pubkey.length > 16
        ? '${pubkey.substring(0, 8)}…${pubkey.substring(pubkey.length - 8)}'
        : pubkey;
    final host = Uri.tryParse(relay)?.host ?? relay;
    return (pubkey: shortPubkey, relay: host);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final info = _parse();

    return AppSheet(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.positive.withValues(alpha: 0.14),
                    borderRadius: AppRadii.br12,
                  ),
                  child: Icon(
                    LucideIcons.check,
                    size: 22,
                    color: colors.positive,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Wallet connected',
                        style: typography.displayM.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.walletName,
                        style: typography.bodyL.copyWith(color: colors.slate),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _InfoRow(
              icon: LucideIcons.server,
              label: 'Relay',
              value: info.relay,
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: LucideIcons.key,
              label: 'Wallet',
              value: info.pubkey,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: _disconnecting ? 'Disconnecting…' : 'Disconnect',
              fullWidth: true,
              variant: AppButtonVariant.danger,
              icon: LucideIcons.unplug,
              isLoading: _disconnecting,
              onTap: _disconnecting ? null : _disconnect,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class AppNwcConnectedSheet extends StatefulWidget {
  final String walletName;
  final String connectionString;
  final Future<void> Function() onDisconnect;

  const AppNwcConnectedSheet({
    super.key,
    required this.walletName,
    required this.connectionString,
    required this.onDisconnect,
  });

  @override
  State<AppNwcConnectedSheet> createState() => _AppNwcConnectedSheetState();

  static Future<void> show(
    BuildContext context, {
    required String walletName,
    required String connectionString,
    required Future<void> Function() onDisconnect,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppNwcConnectedSheet(
        walletName: walletName,
        connectionString: connectionString,
        onDisconnect: onDisconnect,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: colors.paper2,
        borderRadius: AppRadii.br10,
        border: Border.all(color: colors.hairline),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.slate),
          const SizedBox(width: 12),
          Text(label, style: typography.bodyS.copyWith(color: colors.slate)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: typography.mono.copyWith(color: colors.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
