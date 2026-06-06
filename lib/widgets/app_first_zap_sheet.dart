import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_button.dart';
import 'package:zapbook/widgets/app_sheet.dart';

class AppFirstZapSheet extends StatelessWidget {
  final VoidCallback onConnectWallet;
  final VoidCallback onUseUrlLauncher;

  const AppFirstZapSheet({
    super.key,
    required this.onConnectWallet,
    required this.onUseUrlLauncher,
  });

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: context.colors.bitcoinTint,
              borderRadius: AppRadii.br14,
            ),
            child: Icon(
              LucideIcons.zap,
              size: 28,
              color: context.colors.bitcoin,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Seamless zaps',
            style: context.typography.displayM.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colors.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Connect your wallet to zap without leaving ZapBook.',
            textAlign: TextAlign.center,
            style: context.typography.bodyL.copyWith(
              color: context.colors.slate,
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Connect wallet',
            fullWidth: true,
            variant: AppButtonVariant.primary,
            icon: LucideIcons.wallet,
            onTap: onConnectWallet,
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Not now — open in wallet app',
            variant: AppButtonVariant.ghost,
            fullWidth: true,
            onTap: onUseUrlLauncher,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onConnectWallet,
    required VoidCallback onUseUrlLauncher,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppFirstZapSheet(
        onConnectWallet: onConnectWallet,
        onUseUrlLauncher: onUseUrlLauncher,
      ),
    );
  }
}
