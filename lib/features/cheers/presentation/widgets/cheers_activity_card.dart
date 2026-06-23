import 'package:flutter/material.dart';
import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';
import 'package:zapbook/features/cheers/presentation/widgets/cheers_reaction_pill.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_profile_avatar.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';
import 'package:zapbook/core/extensions/date_time_extension.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';

int _getGestureCount(CheersActivity activity, ZapGesture gesture) {
  switch (gesture) {
    case ZapGesture.thumbsUp:
      return activity.thumbsUpCount;
    case ZapGesture.clap:
      return activity.clapCount;
    case ZapGesture.fire:
      return activity.fireCount;
    case ZapGesture.rocket:
      return activity.rocketCount;
    case ZapGesture.trophy:
      return activity.trophyCount;
    case ZapGesture.gift:
      return 0;
  }
}

class CheersActivityCard extends StatelessWidget {
  const CheersActivityCard({
    super.key,
    required this.activity,
    required this.onTap,
    required this.onReactionTap,
    this.onLongPress,
  });

  final CheersActivity activity;
  final VoidCallback onTap;
  final void Function(ZapGesture gesture) onReactionTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final isMine = activity.type == 'mine';
    final isNotice =
        activity.type == 'zap_nudge' || activity.type == 'zap_ready';
    final isZap = activity.type == 'zap';

    final hasReactions = ZapGesture.values.any(
      (g) => _getGestureCount(activity, g) > 0,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: BouncingInteractiveWidget(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.paper3,
            borderRadius: AppRadii.br20,
            border: Border.all(
              color: activity.isUnread ? colors.bitcoin : colors.hairline2,
              width: activity.isUnread ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppProfileAvatar(url: activity.actorAvatar ?? '', size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              activity.actorName,
                              style: typography.bodyL.copyWith(
                                color: colors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              activity.timestamp.formatTimeAgo(),
                              style: typography.caption.copyWith(
                                color: colors.slate,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activity.activityDescription,
                          style: typography.body.copyWith(
                            color: colors.ink2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activity.bookTitle,
                          style: typography.caption.copyWith(
                            color: colors.slate,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!isNotice && !isZap) ...[
                const SizedBox(height: 12),
                if (hasReactions)
                  _ReactionsRow(
                    activity: activity,
                    onReactionTap: onReactionTap,
                    onTap: onTap,
                    isMine: isMine,
                  )
                else if (!isMine)
                  _EmptyReactions(onTap: onTap),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReactionsRow extends StatelessWidget {
  const _ReactionsRow({
    required this.activity,
    required this.onReactionTap,
    required this.onTap,
    required this.isMine,
  });

  final CheersActivity activity;
  final void Function(ZapGesture) onReactionTap;
  final VoidCallback onTap;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...ZapGesture.values
            .where((g) => _getGestureCount(activity, g) > 0)
            .map((g) {
              return ReactionPill(
                emoji: g.emoji,
                count: _getGestureCount(activity, g),
                onTap: () => onReactionTap(g),
              );
            }),
        if (!isMine) AddReactionButton(onTap: onTap),
      ],
    );
  }
}

class _EmptyReactions extends StatelessWidget {
  const _EmptyReactions({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AddReactionButton(onTap: onTap);
  }
}

class ZapAmountPill extends StatelessWidget {
  const ZapAmountPill({super.key, required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.bitcoin.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('⚡', style: typography.bodyS.copyWith(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            '$amount sats',
            style: typography.bodyS.copyWith(
              color: colors.bitcoinDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
