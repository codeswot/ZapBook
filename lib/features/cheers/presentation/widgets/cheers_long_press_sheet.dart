import 'package:zapbook/core/domain/entities/cheers_activity_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/core/presentation/widgets/app_toast.dart';
import 'package:zapbook/features/cheers/presentation/bloc/cheers_cubit.dart';
import 'package:zapbook/features/cheers/presentation/cheers_zap_sheet.dart';
import 'package:zapbook/features/cheers/presentation/widgets/cheers_post_sheet.dart';
import 'package:zapbook/core/presentation/theme/app_radii.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';
import 'package:zapbook/core/presentation/widgets/app_profile_avatar.dart';
import 'package:zapbook/core/presentation/widgets/app_sheet.dart';
import 'package:zapbook/core/presentation/widgets/bouncing_interactive_widget.dart';

class CheersLongPressSheet extends StatelessWidget {
  const CheersLongPressSheet({
    super.key,
    required this.activity,
    required this.cubit,
  });

  final CheersActivity activity;
  final CheersCubit cubit;

  static Future<void> show(
    BuildContext context, {
    required CheersActivity activity,
    required CheersCubit cubit,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: CheersLongPressSheet(activity: activity, cubit: cubit),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final isMine = activity.isMine;

    return AppSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              AppProfileAvatar(url: activity.actorPicture, size: 44),
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
                    const SizedBox(height: 2),
                    Text(
                      activity.targetDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: typography.bodyS.copyWith(color: colors.slate),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (!isMine) ...[
            _Action(
              icon: LucideIcons.zap,
              label: 'Zap',
              tone: colors.bitcoin,
              onTap: () {
                context.pop();
                CheersZapSheet.show(context, activity: activity, cubit: cubit);
              },
            ),
            const SizedBox(height: 10),
          ],
          _Action(
            icon: LucideIcons.copy,
            label: 'Copy',
            tone: colors.ink,
            onTap: () {
              cubit.copyActivityToClipboard(activity);
              context.pop();
              context.toast.showInfo('Copied to clipboard');
            },
          ),
          const SizedBox(height: 10),
          _Action(
            icon: LucideIcons.share2,
            label: 'Share',
            tone: colors.ink,
            onTap: () {
              cubit.shareActivity(activity);
              context.pop();
            },
          ),
          if (activity.type == CheersActivityType.milestone) ...[
            const SizedBox(height: 10),
            _Action(
              icon: LucideIcons.notebookPen,
              label: 'Post as note',
              tone: colors.ink,
              onTap: () {
                context.pop();
                CheersPostSheet.show(context, activity: activity, cubit: cubit);
              },
            ),
          ],
          if (activity.type == CheersActivityType.zapNudge) ...[
            const SizedBox(height: 10),
            _Action(
              icon: LucideIcons.zap,
              label: 'Set up wallet',
              tone: colors.bitcoin,
              onTap: () {
                context.pop();
                context.go('/you');
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tone,
  });

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
                style: context.typography.bodyL.copyWith(
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
