import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/core/presentation/router/app_router.dart';
import 'package:zapbook/features/circles/presentation/bloc/circle_detail_state.dart'
    show MemberProgress;
import 'package:zapbook/features/circles/presentation/bloc/circle_members_state.dart'
    show MemberEntry;
import 'package:zapbook/features/circles/presentation/widgets/circle_detail/circle_progress_bar.dart';
import 'package:zapbook/features/circles/presentation/widgets/reader_zap_sheet.dart';
import 'package:zapbook/core/presentation/theme/app_radii.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/core/presentation/widgets/app_profile_avatar.dart';
import 'package:zapbook/core/presentation/widgets/bouncing_interactive_widget.dart';

class CircleReaderTile extends StatelessWidget {
  const CircleReaderTile({
    super.key,
    required this.entry,
    required this.isOwner,
    required this.isYou,
    required this.pageCount,
    required this.bookTitle,
    required this.circleBookId,
    this.onLongPress,
    required this.memberProgress,
  });

  final MemberEntry entry;
  final bool isOwner;
  final bool isYou;
  final int pageCount;
  final String bookTitle;
  final String circleBookId;
  final VoidCallback? onLongPress;
  final Map<String, MemberProgress> memberProgress;

  void _showZapSheet(BuildContext context) {
    if (isYou) return;
    ReaderZapSheet.show(
      context,
      reader: entry.contact,
      circleId: circleBookId,
      circleBookTitle: bookTitle,
    );
    return;
  }

  void _openProfile(BuildContext context) {
    if (isYou) {
      context.go('/you');
      return;
    }
    UserProfileRoute(npub: entry.npub).push(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final isSelf = entry.isSelf;
    final progress = memberProgress[entry.npub];
    final fraction = progress?.fraction ?? 0;
    final page = progress?.currentPage ?? 0;

    return BouncingInteractiveWidget(
      onLongPress: onLongPress,
      onTap: () => _openProfile(context),
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
                          color: colors.bitcoin.withValues(alpha: 0.3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        page >= 0 ? 'p.${page + 1}' : '—',
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
          color: colors.bitcoin.withValues(alpha: 0.1),
          border: Border.all(color: colors.bitcoin.withValues(alpha: 0.2)),
          borderRadius: AppRadii.br12,
        ),
        child: Icon(LucideIcons.zap, size: 19, color: colors.bitcoin),
      ),
    );
  }
}
