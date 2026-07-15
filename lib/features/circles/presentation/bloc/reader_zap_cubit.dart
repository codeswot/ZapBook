import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/domain/entities/zap_status.dart';
import 'package:zapbook/features/circles/domain/usecases/circles_usecases.dart';

part 'reader_zap_state.dart';

@injectable
class ReaderZapCubit extends Cubit<ReaderZapState> {
  ReaderZapCubit(this._sendCircleZap) : super(const ReaderZapInitial());

  final SendCircleZapUseCase _sendCircleZap;

  Future<void> sendZap({
    required Contact reader,
    required ZapGesture gesture,
    required String circleId,
  }) async {
    emit(ReaderZapLoading(gesture));

    try {
      await _sendCircleZap(
        reader: reader,
        gesture: gesture,
        circleId: circleId,
      );

      emit(
        ReaderZapSuccess(
          amountSats: gesture.sats ?? 0,
          readerLabel: reader.label,
        ),
      );
    } on Exception catch (error) {
      if (error is ZapException) {
        emit(ReaderZapFailure(error.message));
      } else {
        emit(ReaderZapFailure(error.toString()));
      }
    } on Object {
      emit(ReaderZapFailure('Could not zap ${reader.label}'));
    }
  }
}
