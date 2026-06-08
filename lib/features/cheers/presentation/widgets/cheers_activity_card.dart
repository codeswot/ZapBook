import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_profile_avatar.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class CheersActivityCard extends StatelessWidget {
  const CheersActivityCard({
    super.key,
    required this.activity,
    required this.onTap,
    required this.onReactionTap,
  });

  final CheersActivity activity;
  final VoidCallback onTap;
  final void Function(String reactionType) onReactionTap;

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m';
    return 'just now';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    final hasReactions =
        activity.thumbsUpCount > 0 ||
        activity.clapCount > 0 ||
        activity.fireCount > 0 ||
        activity.rocketCount > 0 ||
        activity.trophyCount > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: BouncingInteractiveWidget(
        onTap: onTap,
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
                              _formatTimeAgo(activity.timestamp),
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
                        Row(
                          children: [
                            Text(
                              activity.bookTitle,
                              style: typography.caption.copyWith(
                                color: colors.slate,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              LucideIcons.check,
                              size: 12,
                              color: colors.positive,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '3/3',
                              style: typography.caption.copyWith(
                                color: colors.positive,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (hasReactions)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (activity.thumbsUpCount > 0)
                      _buildReactionPill(
                        context: context,
                        emoji: '👍',
                        count: activity.thumbsUpCount,
                        onTap: () => onReactionTap('like'),
                      ),
                    if (activity.clapCount > 0)
                      _buildReactionPill(
                        context: context,
                        emoji: '👏',
                        count: activity.clapCount,
                        onTap: () => onReactionTap('clap'),
                      ),
                    if (activity.fireCount > 0)
                      _buildReactionPill(
                        context: context,
                        emoji: '🔥',
                        count: activity.fireCount,
                        onTap: () => onReactionTap('fire'),
                      ),
                    if (activity.rocketCount > 0)
                      _buildReactionPill(
                        context: context,
                        emoji: '🚀',
                        count: activity.rocketCount,
                        onTap: () => onReactionTap('rocket'),
                      ),
                    if (activity.trophyCount > 0)
                      _buildReactionPill(
                        context: context,
                        emoji: '🏆',
                        count: activity.trophyCount,
                        onTap: () => onReactionTap('trophy'),
                      ),
                    _buildAddReactionButton(context),
                  ],
                )
              else
                _buildEmptyReactionSkeleton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddReactionButton(BuildContext context) {
    final colors = context.colors;
    return BouncingInteractiveWidget(
      onTap: onTap,
      child: CustomPaint(
        painter: _DottedCirclePainter(
          color: colors.slate.withValues(alpha: 0.6),
        ),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(LucideIcons.plus, size: 14, color: colors.slate),
        ),
      ),
    );
  }

  Widget _buildEmptyReactionSkeleton(BuildContext context) {
    final colors = context.colors;
    return BouncingInteractiveWidget(
      onTap: onTap,
      child: SizedBox(
        height: 32,
        width: 80,
        child: Stack(
          children: [
            Positioned(
              left: 32,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.paper2,
                ),
              ),
            ),
            Positioned(
              left: 16,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.paper4,
                ),
              ),
            ),
            CustomPaint(
              painter: _DottedCirclePainter(color: colors.slate),
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                child: Icon(LucideIcons.plus, size: 14, color: colors.slate),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionPill({
    required BuildContext context,
    required String emoji,
    required int count,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    final typography = context.typography;

    return BouncingInteractiveWidget(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colors.paper4,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: colors.hairline2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: typography.caption.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DottedCirclePainter extends CustomPainter {
  final Color color;
  _DottedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final path = Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height));

    final dashedPath = Path();
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final len = draw ? 3.0 : 3.0;
        if (draw) {
          dashedPath.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DottedCirclePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
