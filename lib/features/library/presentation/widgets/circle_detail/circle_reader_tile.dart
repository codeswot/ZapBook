import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/features/library/presentation/bloc/circle_members_state.dart'
    show MemberEntry;
import 'package:zapbook/features/library/presentation/widgets/circle_detail/circle_placeholders.dart';
import 'package:zapbook/features/library/presentation/widgets/circle_detail/circle_progress_bar.dart';
import 'package:zapbook/features/library/presentation/widgets/reader_zap_sheet.dart';
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
    this.onLongPress,
  });

  final MemberEntry entry;
  final bool isOwner;
  final int pageCount;
  final VoidCallback? onLongPress;

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
          color: isSelf ? colors.nostrTint : colors.paper,
          borderRadius: AppRadii.br16,
          border: Border.all(
            color: isSelf
                ? colors.nostrTint2
                : colors.ink.withValues(alpha: 0.09),
          ),
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
                          isSelf ? 'You' : entry.contact.label,
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
                          color: isSelf ? colors.nostr : colors.bitcoin,
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
              _ZapButton(
                onTap: () => ReaderZapSheet.show(context, entry.contact),
              ),
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
    final isYou = tone == _BadgeTone.you;
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isYou ? colors.nostr : colors.paper3,
        borderRadius: AppRadii.br999,
        border: Border.all(color: isYou ? colors.nostr : colors.hairline),
      ),
      child: Text(
        label,
        style: typography.caption.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: isYou ? colors.white : colors.slate2,
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
