import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/features/library/presentation/bloc/circle_members_state.dart'
    show MemberEntry;
import 'package:zapbook/features/library/presentation/widgets/circle_detail/circle_placeholders.dart';
import 'package:zapbook/features/library/presentation/widgets/circle_detail/circle_progress_bar.dart';
import 'package:flutter/services.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/services/zap_service.dart';
import 'package:zapbook/widgets/zap_sheet.dart';
import 'package:zapbook/widgets/app_toast.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_profile_avatar.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class CircleReaderTile extends StatelessWidget {
  const CircleReaderTile({
    super.key,
    required this.entry,
    required this.isOwner,
    required this.pageCount,
    required this.bookTitle,
    this.onLongPress,
  });

  final MemberEntry entry;
  final bool isOwner;
  final int pageCount;
  final String bookTitle;
  final VoidCallback? onLongPress;

  void _showZapSheet(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    ZapSheet.show(
      context: context,
      header: Row(
        children: [
          AppProfileAvatar(url: entry.contact.picture ?? '', size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Zap ${entry.contact.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.h3.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Reading $bookTitle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.bodyS.copyWith(color: colors.slate),
                ),
              ],
            ),
          ),
        ],
      ),
      onZapSelected: (gesture, amount, message) =>
          _handleZap(context, gesture, amount, message),
    );
  }

  Future<void> _handleZap(
    BuildContext context,
    ZapGesture gesture,
    int amount,
    String? comment,
  ) async {
    final messenger = context.toast;
    final lud16 = entry.contact.lud16;
    if (lud16 == null || lud16.isEmpty) {
      messenger.showError('${entry.contact.label} has no lightning address');
      return;
    }

    try {
      final zap = getIt<ZapService>();
      final result = await zap.send(
        recipientLud16: lud16,
        recipientPubkey: entry.npub,
        targetEventId: '',
        gesture: gesture,
        customSats: amount,
        comment: comment,
      );
      final launched = await zap.payWithFallback(result.invoice);
      if (!launched) {
        await Clipboard.setData(ClipboardData(text: result.invoice));
        messenger.showInfo('Invoice copied to clipboard');
      } else {
        messenger.showSuccess('Zapping $amount sats to ${entry.contact.label}');
      }
    } catch (_) {
      messenger.showError('Could not zap ${entry.contact.label}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final isSelf = entry.isSelf;
    final fraction = circleProgressFraction(entry.npub);
    final page = circleReaderPage(entry.npub, pageCount);

    return GestureDetector(
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.paper,
          borderRadius: AppRadii.br16,
          border: Border.all(color: colors.ink.withValues(alpha: 0.09)),
        ),
        child: Row(
          children: [
            AppProfileAvatar(url: entry.contact.picture ?? '', size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.contact.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: typography.bodyL.copyWith(
                            color: colors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (isSelf)
                        const _Badge(label: 'YOU', tone: _BadgeTone.you)
                      else if (isOwner)
                        const _Badge(label: 'Owner', tone: _BadgeTone.neutral),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: CircleProgressBar(
                          value: fraction,
                          color: colors.bitcoin,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        pageCount > 0 ? 'p.$page' : '—',
                        style: typography.caption.copyWith(
                          color: colors.slate2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isSelf) ...[
              const SizedBox(width: 12),
              _ZapButton(onTap: () => _showZapSheet(context)),
            ],
          ],
        ),
      ),
    );
  }
}

enum _BadgeTone { you, neutral }

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.tone});

  final String label;
  final _BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.paper3,
        borderRadius: AppRadii.br999,
        border: Border.all(color: colors.hairline),
      ),
      child: Text(
        label,
        style: typography.caption.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: colors.ink2,
        ),
      ),
    );
  }
}

class _ZapButton extends StatelessWidget {
  const _ZapButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BouncingInteractiveWidget(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.bitcoin,
          borderRadius: AppRadii.br12,
        ),
        child: Icon(LucideIcons.zap, size: 19, color: colors.bitcoinDark),
      ),
    );
  }
}
