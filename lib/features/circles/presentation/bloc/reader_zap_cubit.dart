import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:zapbook/core/data/dao/zap_sats_earnings_dao.dart';
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/services/zap_nudge_service.dart';
import 'package:zapbook/core/services/zap_service.dart';

part 'reader_zap_state.dart';

@injectable
class ReaderZapCubit extends Cubit<ReaderZapState> {
  ReaderZapCubit(this._zap, this._nudgeService)
    : super(const ReaderZapInitial());

  final ZapService _zap;
  final ZapNudgeService _nudgeService;

  Future<void> sendZap({
    required Contact reader,
    required ZapGesture gesture,
    required String circleId,
  }) async {
    final lud16 = reader.lud16;
    if (lud16 == null || lud16.isEmpty) {
      await _nudgeService.nudge(groupId: circleId, toNpub: reader.npub);
      emit(ReaderZapFailure('${reader.label} has no lightning address'));

      return;
    }

    emit(ReaderZapLoading(gesture));

    try {
      final result = await _zap.send(
        recipientLud16: lud16,
        recipientPubkey: reader.npub,
        targetActivitytId: circleId,
        zapType: ZapType.circle,
        gesture: gesture,
      );

      await _zap.payZap(result);

      emit(
        ReaderZapSuccess(
          amountSats: result.amountSats,
          readerLabel: reader.label,
        ),
      );
    } on ZapException catch (error) {
      emit(ReaderZapFailure(error.message));
    } on Object {
      emit(ReaderZapFailure('Could not zap ${reader.label}'));
    }
  }
}
