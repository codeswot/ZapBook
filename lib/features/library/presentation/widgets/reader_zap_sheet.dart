import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/services/zap_service.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_profile_avatar.dart';
import 'package:zapbook/widgets/app_sheet.dart';
import 'package:zapbook/widgets/app_toast.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class ReaderZapSheet extends StatelessWidget {
  const ReaderZapSheet({super.key, required this.reader});

  final Contact reader;

  static const _presets = [
    ZapGesture.thumbsUp,
    ZapGesture.clap,
    ZapGesture.fire,
  ];

  static Future<void> show(BuildContext context, Contact reader) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: context.colors.transparent,
      builder: (_) => ReaderZapSheet(reader: reader),
    );
  }

  Future<void> _zap(BuildContext context, ZapGesture gesture) async {
    final messenger = context.toast;
    final navigator = Navigator.of(context);
    final lud16 = reader.lud16;
    if (lud16 == null || lud16.isEmpty) {
      navigator.pop();
      messenger.showError('${reader.label} has no lightning address');
      return;
    }
    navigator.pop();
    try {
      final zap = getIt<ZapService>();
      final result = await zap.send(
        recipientLud16: lud16,
        recipientPubkey: '',
        targetEventId: '',
        gesture: gesture,
      );
      final support = result.hasSupportZap
          ? ' (+${result.supportAmount} to ZapBook)'
          : '';
      await zap.payZap(result);
      messenger.showSuccess(
        'Zapping ${result.amountSats} sats to ${reader.label}$support',
      );
    } on ZapException catch (error) {
      messenger.showError(error.message);
    } on Object {
      messenger.showError('Could not zap ${reader.label}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return AppSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              AppProfileAvatar(url: reader.picture ?? '', size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Zap ${reader.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.h3.copyWith(color: colors.ink),
                    ),
                    Text(
                      'Cheer them on with sats',
                      style: typography.bodyS.copyWith(color: colors.slate),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          for (final gesture in _presets) ...[
            _ZapPreset(gesture: gesture, onTap: () => _zap(context, gesture)),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ZapPreset extends StatelessWidget {
  const _ZapPreset({required this.gesture, required this.onTap});

  final ZapGesture gesture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return BouncingInteractiveWidget(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.paper3,
          borderRadius: AppRadii.br12,
          border: Border.all(color: colors.hairline),
        ),
        child: Row(
          children: [
            Text(gesture.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                gesture.label,
                style: typography.bodyL.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Row(
              children: [
                Icon(LucideIcons.zap, size: 15, color: colors.bitcoin),
                const SizedBox(width: 4),
                Text(
                  '${gesture.sats}',
                  style: typography.bodyL.copyWith(
                    color: colors.bitcoin,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
