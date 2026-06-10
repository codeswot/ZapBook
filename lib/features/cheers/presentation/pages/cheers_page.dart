import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ndk/ndk.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';

import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';
import 'package:zapbook/features/cheers/presentation/bloc/cheers_cubit.dart';
import 'package:zapbook/features/cheers/presentation/bloc/cheers_state.dart';
import 'package:zapbook/features/cheers/presentation/widgets/cheers_activity_card.dart';
import 'package:zapbook/features/cheers/presentation/widgets/cheers_shimmer.dart';
import 'package:zapbook/widgets/zap_sheet.dart';
import 'package:zapbook/widgets/zap_nudge_sheet.dart';
import 'package:zapbook/widgets/app_toast.dart';
import 'package:zapbook/widgets/app_profile_avatar.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zapbook/widgets/app_sheet.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';

class CheersPage extends StatelessWidget {
  const CheersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CheersCubit>(
      create: (_) => getIt<CheersCubit>(),
      child: const _CheersView(),
    );
  }
}

class _CheersView extends StatefulWidget {
  const _CheersView();

  @override
  State<_CheersView> createState() => _CheersViewState();
}

class _CheersViewState extends State<_CheersView> {
  String _selectedFilter = 'All';
  final Set<String> _buzzedSeen = {};

  final List<String> _filters = ['All', 'Milestones', 'Zaps', 'Mine'];

  List<CheersActivity> _filterActivities(List<CheersActivity> list) {
    final visible = list.where((a) => a.type != 'zap_ready');
    if (_selectedFilter == 'All') return visible.toList();
    if (_selectedFilter == 'Milestones') {
      return visible
          .where((a) => a.type == 'milestone' || a.type == 'mine')
          .toList();
    }
    if (_selectedFilter == 'Zaps') {
      return visible
          .where(
            (a) =>
                a.type == 'zap_nudge' ||
                a.thumbsUpCount > 0 ||
                a.clapCount > 0 ||
                a.fireCount > 0 ||
                a.rocketCount > 0 ||
                a.trophyCount > 0,
          )
          .toList();
    }
    if (_selectedFilter == 'Mine') {
      return visible.where((a) => a.type == 'mine').toList();
    }
    return visible.toList();
  }

  void _surfaceBuzzes(BuildContext context, List<CheersActivity> list) {
    for (final activity in list.where((a) => a.type == 'zap_ready')) {
      if (!_buzzedSeen.add(activity.id)) continue;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.toast.showInfo(activity.activityDescription);
      });
    }
  }

  void _showZapSheet(BuildContext context, CheersActivity activity) {
    if (activity.type == 'mine') {
      return;
    }
    final colors = context.colors;
    final typography = context.typography;
    ZapSheet.show(
      context: context,
      header: Row(
        children: [
          AppProfileAvatar(url: activity.actorAvatar ?? '', size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Zap ${activity.actorName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.h3.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${activity.activityDescription}:',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.bodyS.copyWith(color: colors.slate),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.bookTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.body.copyWith(color: colors.slate2),
                ),
              ],
            ),
          ),
        ],
      ),
      onZapSelected: (gesture, amount, message) =>
          _handleZap(context, activity, gesture, amount, message),
    );
  }

  Future<void> _handleZap(
    BuildContext context,
    CheersActivity activity,
    ZapGesture gesture,
    int amount,
    String? comment,
  ) async {
    if (activity.type == 'mine') {
      return;
    }

    final messenger = context.toast;
    final cubit = context.read<CheersCubit>();

    final reactionType = gesture == ZapGesture.thumbsUp
        ? 'like'
        : gesture == ZapGesture.clap
        ? 'clap'
        : gesture == ZapGesture.fire
        ? 'fire'
        : gesture == ZapGesture.rocket
        ? 'rocket'
        : gesture == ZapGesture.trophy
        ? 'trophy'
        : 'like';

    await cubit.sendZap(
      activityId: activity.id,
      amount: amount,
      reactionType: reactionType,
    );

    try {
      final pubkey = Nip19.decode(activity.actorNpub);
      final lud16 = await cubit.lookupLud16(pubkey);
      if (lud16 != null && lud16.isNotEmpty) {
        final result = await cubit.externalZap(
          recipientLud16: lud16,
          recipientPubkey: pubkey,
          gesture: gesture,
          amount: amount,
          comment: comment,
        );
        await cubit.payInvoice(result.invoice);
        messenger.showSuccess('Zapping $amount sats to ${activity.actorName}');
      } else {
        await cubit.nudge(
          groupId: activity.id.split(':').first,
          toNpub: activity.actorNpub,
        );
        if (!context.mounted) return;
        await ZapNudgeSheet.show(
          context,
          title: "${activity.actorName} can't be zapped yet",
          message:
              "${activity.actorName} hasn't set up their lightning wallet. "
              "We've let them know — you'll get a heads-up here when they're "
              'ready.',
        );
      }
    } catch (_) {
      messenger.showInfo('Reacted with ${gesture.emoji}!');
    }
  }

  void _showLongPressMenu(BuildContext context, CheersActivity activity) {
    final colors = context.colors;
    final typography = context.typography;
    final isMine = activity.type == 'mine';

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AppSheet(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  AppProfileAvatar(url: activity.actorAvatar ?? '', size: 44),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isMine ? 'My Progress' : activity.actorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: typography.h3.copyWith(color: colors.ink),
                        ),
                        Text(
                          '${activity.activityDescription} • ${activity.bookTitle}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: typography.bodyS.copyWith(color: colors.slate),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (isMine) ...[
                MenuRow(
                  context: context,
                  icon: LucideIcons.share2,
                  label: 'Share progress externally',
                  onTap: () async {
                    context.pop();
                    final text =
                        'Look at my progress on ZapBook! Just ${activity.activityDescription} of "${activity.bookTitle}" ⚡';
                    await SharePlus.instance.share(ShareParams(text: text));
                  },
                ),
                const SizedBox(height: 10),
                MenuRow(
                  context: context,
                  icon: LucideIcons.copy,
                  label: 'Copy achievement text',
                  onTap: () async {
                    final messenger = context.toast;
                    context.pop();
                    final text =
                        'Look at my progress on ZapBook! Just ${activity.activityDescription} of "${activity.bookTitle}" ⚡';
                    await Clipboard.setData(ClipboardData(text: text));
                    messenger.showInfo('Achievement text copied to clipboard!');
                  },
                ),
              ] else ...[
                MenuRow(
                  context: context,
                  icon: LucideIcons.zap,
                  label: 'Zap ${activity.actorName}',
                  tone: colors.bitcoin,
                  onTap: () {
                    context.pop();
                    _showZapSheet(context, activity);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleNudgeTap(
    BuildContext context,
    CheersActivity activity,
  ) async {
    final messenger = context.toast;
    final cubit = context.read<CheersCubit>();
    final lud16 = await cubit.getMyLud16();

    if (lud16 == null || lud16.isEmpty) {
      if (!context.mounted) return;
      await ZapNudgeSheet.show(
        context,
        title: 'Set up your wallet',
        message:
            '${activity.actorName} wants to zap you. Add your lightning '
            'address in your profile to receive it, then come back and tap '
            'this card to buzz them.',
        actionLabel: 'Go to profile',
        onAction: () => context.go('/you'),
      );
      return;
    }

    await cubit.nudgeReady(
      groupId: activity.id.split(':').first,
      nudgeId: activity.nudgeId ?? '',
      toNpub: activity.actorNpub,
    );
    messenger.showSuccess("Buzzed ${activity.actorName} — you're all set!");
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Scaffold(
      backgroundColor: colors.paper,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SOCIAL CELEBRATIONS',
                    style: typography.caption.copyWith(
                      color: colors.bitcoin,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cheers',
                        style: typography.h1.copyWith(
                          color: colors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = filter == _selectedFilter;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        filter,
                        style: typography.bodyS.copyWith(
                          color: isSelected ? colors.bitcoinDark : colors.slate,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        }
                      },
                      selectedColor: colors.bitcoin,
                      backgroundColor: colors.paper3,
                      checkmarkColor: colors.bitcoinDark,
                      showCheckmark: false,
                      side: BorderSide(
                        color: isSelected ? colors.bitcoin : colors.hairline2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<CheersCubit, CheersState>(
                builder: (context, state) {
                  if (state is CheersLoading) {
                    return const CheersShimmer();
                  }

                  if (state is CheersError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          state.message,
                          style: typography.bodyS.copyWith(color: colors.coral),
                        ),
                      ),
                    );
                  }

                  final list = (state as CheersLoaded).activities;
                  _surfaceBuzzes(context, list);
                  final filtered = _filterActivities(list);

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.sparkles,
                              size: 40,
                              color: colors.slate,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No cheers found',
                              style: typography.h3.copyWith(color: colors.ink),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Activities from your circles will show up here.',
                              textAlign: TextAlign.center,
                              style: typography.bodyS.copyWith(
                                color: colors.slate,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return CheersActivityCard(
                        activity: item,
                        onTap: () => item.type == 'zap_nudge'
                            ? _handleNudgeTap(context, item)
                            : _showZapSheet(context, item),
                        onLongPress: () => item.type == 'zap_nudge'
                            ? _handleNudgeTap(context, item)
                            : _showLongPressMenu(context, item),
                        onReactionTap: (type) {
                          if (item.type == 'mine') {
                            return;
                          }
                          final gesture = type == 'like'
                              ? ZapGesture.thumbsUp
                              : type == 'clap'
                              ? ZapGesture.clap
                              : type == 'fire'
                              ? ZapGesture.fire
                              : type == 'rocket'
                              ? ZapGesture.rocket
                              : type == 'trophy'
                              ? ZapGesture.trophy
                              : ZapGesture.thumbsUp;
                          _handleZap(
                            context,
                            item,
                            gesture,
                            gesture.sats ?? 21,
                            null,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MenuRow extends StatelessWidget {
  const MenuRow({
    super.key,
    required this.context,
    required this.icon,
    required this.label,
    required this.onTap,
    this.tone,
  });
  final BuildContext context;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? tone;
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = tone ?? colors.ink;
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
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: context.typography.body.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
