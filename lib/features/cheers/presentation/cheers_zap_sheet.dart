import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zapbook/core/presentation/widgets/app_profile_avatar.dart';
import 'package:zapbook/core/presentation/widgets/zap_sheet.dart';
import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';
import 'package:zapbook/features/cheers/presentation/bloc/cheers_cubit.dart';
import 'package:zapbook/theme/app_theme.dart';

class CheersZapSheet extends StatelessWidget {
  const CheersZapSheet({super.key, required this.activity});
  final CheersActivity activity;

  static Future<void> show(
    BuildContext context, {
    required CheersActivity activity,
    CheersCubit? cubit,
  }) {
    final effectiveCubit = cubit ?? context.read<CheersCubit>();
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: context.colors.transparent,
      builder: (_) => BlocProvider.value(
        value: effectiveCubit,
        child: CheersZapSheet(activity: activity),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final bookCircleTitle = activity.bookCircleTitle ?? '';
    return ZapSheet(
      header: Row(
        children: [
          AppProfileAvatar(url: activity.actorPicture, size: 48),
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
                  '${activity.targetDescription}:',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.bodyS.copyWith(color: colors.slate),
                ),
                if (bookCircleTitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    bookCircleTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.body.copyWith(color: colors.slate2),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      onZapSelected: (gesture, amount, message) =>
          context.read<CheersCubit>().performZap(
            activity: activity,
            gesture: gesture,
            amount: amount,
            comment: message,
          ),
    );
  }
}
