import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ndk/ndk.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/services/nostr_service.dart';
import 'package:zapbook/core/services/zap_service.dart';
import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';
import 'package:zapbook/features/cheers/presentation/bloc/cheers_cubit.dart';
import 'package:zapbook/features/cheers/presentation/bloc/cheers_state.dart';
import 'package:zapbook/features/cheers/presentation/widgets/cheers_activity_card.dart';
import 'package:zapbook/features/cheers/presentation/widgets/cheers_shimmer.dart';
import 'package:zapbook/widgets/zap_sheet.dart';
import 'package:zapbook/widgets/app_toast.dart';
import 'package:zapbook/widgets/app_profile_avatar.dart';
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

  final List<String> _filters = ['All', 'Milestones', 'Zaps', 'Mine'];

  List<CheersActivity> _filterActivities(List<CheersActivity> list) {
    if (_selectedFilter == 'All') return list;
    if (_selectedFilter == 'Milestones') {
      return list
          .where((a) => a.type == 'milestone' || a.type == 'mine')
          .toList();
    }
    if (_selectedFilter == 'Zaps') {
      return list
          .where(
            (a) =>
                a.thumbsUpCount > 0 ||
                a.clapCount > 0 ||
                a.fireCount > 0 ||
                a.rocketCount > 0 ||
                a.trophyCount > 0,
          )
          .toList();
    }
    if (_selectedFilter == 'Mine') {
      return list.where((a) => a.type == 'mine').toList();
    }
    return list;
  }

  void _showZapSheet(BuildContext context, CheersActivity activity) {
    if (activity.type == 'mine') {
      context.toast.showInfo('You cannot zap yourself');
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
      context.toast.showInfo('You cannot zap yourself');
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
      final meta = await getIt<NostrService>().getMetadata(pubkey);
      final lud16 = meta?.lud16;
      if (lud16 != null && lud16.isNotEmpty) {
        final zap = getIt<ZapService>();
        final result = await zap.send(
          recipientLud16: lud16,
          recipientPubkey: pubkey,
          targetEventId: activity.id.split(':').last,
          gesture: gesture,
          customSats: amount,
          comment: comment,
        );
        await zap.payWithFallback(result.invoice);
        messenger.showSuccess('Zapping $amount sats to ${activity.actorName}');
      } else {
        messenger.showInfo(
          'Reacted! (No Lightning address found for ${activity.actorName})',
        );
      }
    } catch (_) {
      messenger.showInfo('Reacted with ${gesture.emoji}!');
    }
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
                        onTap: () => _showZapSheet(context, item),
                        onReactionTap: (type) {
                          if (item.type == 'mine') {
                            context.toast.showInfo('You cannot zap yourself');
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
