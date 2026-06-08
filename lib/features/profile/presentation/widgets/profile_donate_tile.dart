import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/services/zap_service.dart';
import 'package:zapbook/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';
import 'package:zapbook/widgets/zap_sheet.dart';
import 'package:zapbook/widgets/app_toast.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_tile.dart';
import 'package:zapbook/theme/app_theme.dart';

class ProfileDonateTile extends StatelessWidget {
  const ProfileDonateTile({super.key});

  void _showDonateSheet(BuildContext context, String recipient) {
    final colors = context.colors;
    final typography = context.typography;
    ZapSheet.show(
      context: context,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Support ZapBook',
            style: typography.displayM.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 8),
          BouncingInteractiveWidget(
            onTap: () {
              Clipboard.setData(ClipboardData(text: recipient));
              context.toast.showInfo(
                'Lightning address copied',
                rootNavigator: true,
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.zap, size: 14, color: colors.bitcoin),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    recipient,
                    style: typography.mono.copyWith(
                      color: colors.slate,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(LucideIcons.copy, size: 13, color: colors.slate2),
              ],
            ),
          ),
        ],
      ),

      onZapSelected: (gesture, amount, message) =>
          _handleDonate(context, gesture, amount, message),
    );
  }

  static const _donationMessages = {
    ZapGesture.thumbsUp: 'Well done',
    ZapGesture.clap: 'ZapBook is awesome',
    ZapGesture.fire: 'Keep building ZapBook',
    ZapGesture.rocket: 'ZapBook To the moon!',
    ZapGesture.trophy: 'Absolutely legendary!',
  };

  Future<void> _handleDonate(
    BuildContext context,
    ZapGesture gesture,
    int amount,
    String? comment,
  ) async {
    final messenger = context.toast;

    try {
      final zap = getIt<ZapService>();
      final result = await zap.donate(
        amountSats: amount,
        comment: comment ?? _donationMessages[gesture] ?? gesture.label,
      );
      final launched = await zap.payWithFallback(result.invoice);
      if (!launched) {
        await Clipboard.setData(ClipboardData(text: result.invoice));
        messenger.showInfo('Invoice copied to clipboard');
      } else {
        messenger.showSuccess('Zapping $amount sats to support ZapBook');
      }
    } catch (_) {
      messenger.showError('Could not send donation');
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipient = context.read<ProfileCubit>().donationRecipient;
    final colors = context.colors;
    return ProfileTile(
      icon: LucideIcons.zap,
      iconColor: colors.bitcoin,
      title: 'Support ZapBook',
      subtitle: recipient,
      onTap: () => _showDonateSheet(context, recipient),
    );
  }
}
