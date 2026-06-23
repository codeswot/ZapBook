import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';
import 'package:zapbook/features/cheers/presentation/bloc/cheers_cubit.dart';
import 'package:zapbook/features/cheers/presentation/bloc/cheers_state.dart';
import 'package:zapbook/features/cheers/presentation/widgets/cheers_activity_card.dart';
import 'package:zapbook/features/cheers/presentation/widgets/cheers_shimmer.dart';
import 'package:zapbook/widgets/zap_sheet.dart';
import 'package:zapbook/widgets/zap_nudge_sheet.dart';
import 'package:zapbook/widgets/app_toast.dart';
import 'package:zapbook/widgets/app_profile_avatar.dart';
import 'package:zapbook/features/cheers/presentation/widgets/cheers_long_press_sheet.dart';
import 'package:zapbook/theme/app_theme.dart';

class CheersView extends StatefulWidget {
  const CheersView({super.key});

  @override
  State<CheersView> createState() => _CheersViewState();
}

class _CheersViewState extends State<CheersView> {
  final List<String> _filters = ['All', 'Milestones', 'Zaps', 'Notification'];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<CheersCubit>().loadMore();
    }
  }


  void _showZapSheet(BuildContext context, CheersActivity activity) {
    if (activity.type == 'mine' || activity.actorName == 'You') {
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
      onZapSelected: (gesture, amount, message) {
        context.read<CheersCubit>().performZap(
          activity: activity,
          gesture: gesture,
          amount: amount,
          comment: message,
        );
      },
    );
  }

  void _showLongPressMenu(BuildContext context, CheersActivity activity) {
    CheersLongPressSheet.show(
      context,
      activity: activity,
      cubit: context.read<CheersCubit>(),
    );
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
              child: BlocBuilder<CheersCubit, CheersState>(
                buildWhen: (prev, current) => current is CheersLoaded,
                builder: (context, state) {
                  final activeFilter = state is CheersLoaded ? state.activeFilter : 'All';
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _filters.length,
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final isSelected = filter == activeFilter;

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
                              context.read<CheersCubit>().setFilter(filter);
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
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocConsumer<CheersCubit, CheersState>(
                listenWhen: (prev, current) => current is CheersActionState,
                listener: (context, state) {
                  if (state is CheersZapSuccess) {
                    context.toast.showSuccess(state.message);
                  } else if (state is CheersZapInfo) {
                    context.toast.showInfo(state.message);
                  } else if (state is CheersZapError) {
                    context.toast.showError(state.message);
                  } else if (state is CheersNudgeSuccess) {
                    context.toast.showSuccess(state.message);
                  } else if (state is CheersNudgeRequired) {
                    ZapNudgeSheet.show(
                      context,
                      title: state.title,
                      message: state.message,
                    );
                  } else if (state is CheersNudgeSetupRequired) {
                    ZapNudgeSheet.show(
                      context,
                      title: state.title,
                      message: state.message,
                      actionLabel: 'Go to profile',
                      onAction: () => context.go('/you'),
                    );
                  }
                },
                buildWhen: (prev, current) => current is! CheersActionState,
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

                  if (state is CheersLoaded) {
                    final filtered = state.activities;

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
                                style: typography.h3.copyWith(
                                  color: colors.ink,
                                ),
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
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return CheersActivityCard(
                          activity: item,
                          onTap: () {
                            if (item.type == 'zap_nudge') {
                              context.read<CheersCubit>().performNudge(item);
                            } else {
                              _showZapSheet(context, item);
                            }
                          },
                          onLongPress: () {
                            if (item.type == 'zap_nudge') {
                              context.read<CheersCubit>().performNudge(item);
                            } else if (item.type != 'zap') {
                              _showLongPressMenu(context, item);
                            }
                          },
                          onReactionTap: (gesture) {
                            if (item.type == 'mine') {
                              return;
                            }
                            context.read<CheersCubit>().performZap(
                              activity: item,
                              gesture: gesture,
                              amount: gesture.sats ?? 21,
                            );
                          },
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
