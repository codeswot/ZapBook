import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/features/profile/domain/entities/user_profile.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_button.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class ProfileWalletCard extends StatelessWidget {
  const ProfileWalletCard({
    super.key,
    required this.profile,
    required this.onWallet,
    required this.onCopyLightning,
  });

  final UserProfile profile;
  final VoidCallback onWallet;
  final VoidCallback onCopyLightning;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final formatted = NumberFormat.decimalPattern().format(profile.satsEarned);

    return Container(
      decoration: BoxDecoration(
        color: colors.paper2,
        borderRadius: AppRadii.br24,
        border: Border.all(color: colors.bitcoin.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ).copyWith(top: 16, bottom: 13),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.bitcoin,
                    borderRadius: AppRadii.br12,
                  ),
                  child: Icon(
                    LucideIcons.zap,
                    size: 20,
                    color: colors.bitcoinDark,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Earned reading',
                        style: typography.bodyS.copyWith(color: colors.slate),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            formatted,
                            style: typography.h2.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.ink,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'sats',
                            style: typography.bodyS.copyWith(
                              color: colors.slate,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppButton(
                  label: 'Wallet',
                  variant: AppButtonVariant.tonal,
                  size: AppButtonSize.sm,
                  onTap: onWallet,
                ),
              ],
            ),
          ),

          if (profile.hasLightning) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onCopyLightning,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: colors.paper,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                  border: Border(top: BorderSide(color: colors.hairline)),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.wallet, size: 15, color: colors.slate),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        profile.lightningAddress,
                        style: typography.mono.copyWith(color: colors.slate),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    BouncingInteractiveWidget(
                      onTap: onCopyLightning,
                      child: Icon(
                        LucideIcons.copy,
                        size: 15,
                        color: colors.slate,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
