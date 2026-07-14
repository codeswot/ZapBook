import 'package:flutter/material.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/presentation/widgets/zap_sheet.dart';
import 'package:zapbook/features/circles/presentation/bloc/reader_zap_cubit.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/core/presentation/widgets/app_profile_avatar.dart';
import 'package:zapbook/core/presentation/widgets/app_toast.dart';

class ReaderZapSheet extends StatelessWidget {
  const ReaderZapSheet({
    super.key,
    required this.reader,
    required this.circleId,
    required this.circleBookTitle,
  });

  final Contact reader;
  final String circleId;
  final String circleBookTitle;

  static Future<void> show(
    BuildContext context, {
    required Contact reader,
    required String circleId,
    required String circleBookTitle,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: context.colors.transparent,
      builder: (_) => ReaderZapSheet(
        reader: reader,
        circleId: circleId,
        circleBookTitle: circleBookTitle,
      ),
    );
  }

  Future<void> _zap(BuildContext context, ZapGesture gesture) async {
    final messenger = context.toast;
    final cubit = getIt<ReaderZapCubit>();
    await cubit.sendZap(reader: reader, gesture: gesture, circleId: circleId);

    final state = cubit.state;
    if (state is ReaderZapSuccess) {
      messenger.showSuccess(
        'Zapping ${state.amountSats} sats to ${state.readerLabel}',
      );
    } else if (state is ReaderZapFailure) {
      messenger.showError(state.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return ZapSheet(
      header: Row(
        children: [
          AppProfileAvatar(url: reader.picture ?? '', size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Zap ${reader.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.h3.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Reading $circleBookTitle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.bodyS.copyWith(color: colors.slate),
                ),
              ],
            ),
          ),
        ],
      ),
      onZapSelected: (gesture, amount, message) => _zap(context, gesture),
    );
  }
}
