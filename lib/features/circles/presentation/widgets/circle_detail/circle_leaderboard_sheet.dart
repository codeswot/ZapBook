import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:zapbook/core/presentation/router/app_router.dart';
import 'package:zapbook/core/presentation/theme/app_radii.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/core/presentation/widgets/app_profile_avatar.dart';
import 'package:zapbook/core/presentation/widgets/app_sheet.dart';
import 'package:zapbook/core/presentation/widgets/bouncing_interactive_widget.dart';
import 'package:zapbook/features/circles/presentation/bloc/circle_detail_cubit.dart';
import 'package:zapbook/features/circles/presentation/bloc/circle_detail_state.dart';
import 'package:zapbook/features/circles/presentation/bloc/circle_members_state.dart'
    show MemberEntry;
import 'package:zapbook/features/circles/presentation/widgets/circle_detail/circle_progress_bar.dart';

class CircleLeaderboardSheet extends StatelessWidget {
  const CircleLeaderboardSheet({super.key});

  static Future<void> show(
    BuildContext context, {
    required CircleDetailCubit cubit,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: context.colors.transparent,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const CircleLeaderboardSheet(),
      ),
    );
  }

  void _openProfile(BuildContext context, MemberEntry entry) {
    context.pop();
    if (entry.isSelf) {
      context.go('/you');
    } else {
      UserProfileRoute(npub: entry.npub).push(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      child: BlocBuilder<CircleDetailCubit, CircleDetailState>(
        builder: (context, state) {
          if (state is! CircleDetailLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final colors = context.colors;
          final typography = context.typography;
          final members = state.members;
          final memberProgress = state.memberProgress;

          final sortedMembers = List<MemberEntry>.from(members)
            ..sort(memberProgress.compareEntries);

          MemberEntry? selfEntry;
          int selfRank = 0;
          for (int i = 0; i < sortedMembers.length; i++) {
            if (sortedMembers[i].isSelf) {
              selfEntry = sortedMembers[i];
              selfRank = i + 1;
              break;
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Text(
                  'Leaderboard',
                  style: typography.h2.copyWith(color: colors.ink),
                ),
              ),
              const SizedBox(height: 32),
              if (selfEntry != null)
                _CurrentUserHighlight(
                  entry: selfEntry,
                  rank: selfRank,
                  progress: memberProgress[selfEntry.npub],
                  onTap: () => _openProfile(context, selfEntry!),
                ),
              const SizedBox(height: 32),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 16),
                  physics: const ClampingScrollPhysics(),
                  itemCount: sortedMembers.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entry = sortedMembers[index];
                    final rank = index + 1;
                    return _LeaderboardRow(
                      rank: rank,
                      entry: entry,
                      progress: memberProgress[entry.npub],
                      onTap: () => _openProfile(context, entry),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _rankEmoji(int rank) {
  switch (rank) {
    case 1:
      return '🥇';
    case 2:
      return '🥈';
    case 3:
      return '🥉';
    default:
      return '#$rank';
  }
}

class _CurrentUserHighlight extends StatelessWidget {
  const _CurrentUserHighlight({
    required this.entry,
    required this.rank,
    required this.progress,
    required this.onTap,
  });

  final MemberEntry entry;
  final int rank;
  final MemberProgress? progress;
  final VoidCallback onTap;

  Color _getRankColor(BuildContext context, int rank) {
    final colors = context.colors;
    switch (rank) {
      case 1:
        return colors.butter;
      case 2:
        return colors.slate;
      case 3:
        return colors.coral;
      default:
        return colors.plum;
    }
  }

  Widget _buildRankBadge(BuildContext context, int rank) {
    final colors = context.colors;
    final typography = context.typography;

    if (rank <= 3) {
      return Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: colors.paper, shape: BoxShape.circle),
        child: Text(
          _rankEmoji(rank),
          style: const TextStyle(fontSize: 24, height: 1),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _getRankColor(context, rank),
        borderRadius: AppRadii.br999,
        border: Border.all(color: colors.paper, width: 2),
      ),
      child: Text(
        _rankEmoji(rank),
        style: typography.h3.copyWith(color: colors.paper, height: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final fraction = progress?.fraction ?? 0.0;
    final page = progress?.currentPage ?? 0;
    final rankColor = _getRankColor(context, rank);

    return BouncingInteractiveWidget(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AppProfileAvatar(
                url: entry.contact.picture ?? '',
                size: 88,
                borderColor: rankColor,
                borderWidth: 4,
              ),
              Positioned(
                bottom: -8,
                left: 0,
                right: 0,
                child: Center(child: _buildRankBadge(context, rank)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('You', style: typography.h3.copyWith(color: colors.ink)),
          const SizedBox(height: 4),
          Text(
            '${(fraction * 100).toInt()}% • p.${page + 1}',
            style: typography.body.copyWith(
              color: colors.slate2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.rank,
    required this.entry,
    required this.progress,
    required this.onTap,
  });

  final int rank;
  final MemberEntry entry;
  final MemberProgress? progress;
  final VoidCallback onTap;

  Color _getRankColor(BuildContext context, int rank) {
    final colors = context.colors;
    switch (rank) {
      case 1:
        return colors.butter;
      case 2:
        return colors.slate;
      case 3:
        return colors.coral;
      default:
        return colors.paper4;
    }
  }

  Color _getRankTextColor(BuildContext context, int rank) {
    final colors = context.colors;
    return rank <= 3 ? colors.paper : colors.slate2;
  }

  Widget _buildRankBadge(BuildContext context, int rank) {
    final colors = context.colors;
    final typography = context.typography;

    if (rank <= 3) {
      return Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: colors.paper3, shape: BoxShape.circle),
        child: Text(
          _rankEmoji(rank),
          style: const TextStyle(fontSize: 16, height: 1),
        ),
      );
    }

    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _getRankColor(context, rank),
        shape: BoxShape.circle,
        border: Border.all(color: colors.paper3, width: 2),
      ),
      child: Text(
        _rankEmoji(rank),
        style: typography.caption.copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: _getRankTextColor(context, rank),
          height: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final fraction = progress?.fraction ?? 0;
    final page = progress?.currentPage ?? 0;

    return BouncingInteractiveWidget(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.paper3,
          borderRadius: AppRadii.br16,
          border: Border.all(color: colors.hairline),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AppProfileAvatar(url: entry.contact.picture ?? '', size: 48),
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: _buildRankBadge(context, rank),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          rank <= 3
                              ? '${entry.contact.label} #$rank '
                              : entry.contact.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: typography.bodyL.copyWith(
                            color: colors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (entry.isSelf)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colors.paper,
                            borderRadius: AppRadii.br999,
                            border: Border.all(color: colors.hairline),
                          ),
                          child: Text(
                            'YOU',
                            style: typography.caption.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: colors.ink2,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: CircleProgressBar(
                          value: fraction,
                          color: colors.slate.withValues(alpha: 0.3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${(fraction * 100).toInt()}% • p.${page + 1}',
                        style: typography.caption.copyWith(
                          color: colors.slate2,
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
      ),
    );
  }
}
