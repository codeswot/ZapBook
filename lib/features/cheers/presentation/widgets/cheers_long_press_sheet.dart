import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zapbook/features/cheers/presentation/bloc/cheers_cubit.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';
import 'package:zapbook/core/presentation/widgets/app_profile_avatar.dart';
import 'package:zapbook/core/presentation/widgets/app_sheet.dart';
import 'package:zapbook/core/presentation/widgets/bouncing_interactive_widget.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';

class CheersLongPressSheet extends StatelessWidget {
  const CheersLongPressSheet({
    super.key,
    required this.activity,
    required this.cubit,
    required this.actorName,
    required this.actorAvatar,
    required this.bookTitle,
  });

  final CheersActivity activity;
  final CheersCubit cubit;
  final String actorName;
  final String? actorAvatar;
  final String bookTitle;

  static Future<void> show(
    BuildContext context, {
    required CheersActivity activity,
    required CheersCubit cubit,
    required String actorName,
    required String? actorAvatar,
    required String bookTitle,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CheersLongPressSheet(
        activity: activity,
        cubit: cubit,
        actorName: actorName,
        actorAvatar: actorAvatar,
        bookTitle: bookTitle,
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
              AppProfileAvatar(url: actorAvatar ?? '', size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isMine ? 'My Progress' : actorName,
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
                cubit.performZap(
                  activity: activity,
                  amount: 21,
                  gesture: ZapGesture.thumbsUp,
                  actorName: actorName,
                );
              },
            ),
            const SizedBox(height: 10),
            _Action(
              icon: LucideIcons.nfc,
              label: 'Custom zap',
              tone: colors.bitcoin,
              onTap: () {
                context.pop();
                cubit.performZap(
                  activity: activity,
                  amount: 210,
                  gesture: ZapGesture.fire,
                  actorName: actorName,
                );
              },
            ),
            const SizedBox(height: 10),
          ],
          _Action(
            icon: LucideIcons.copy,
            label: 'Copy',
            tone: colors.ink,
            onTap: () {
              Clipboard.setData(
                ClipboardData(
                  text: '$actorName: ${activity.targetDescription}',
                ),
              );
              context.pop();
            },
          ),
          const SizedBox(height: 10),
          _Action(
            icon: LucideIcons.share2,
            label: 'Share',
            tone: colors.ink,
            onTap: () {
              SharePlus.instance.share(
                ShareParams(
                  text:
                      '$actorName: ${activity.targetDescription} — $bookTitle',
                ),
              );
              context.pop();
            },
          ),
          if (activity.type == 'zap_nudge') ...[
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
