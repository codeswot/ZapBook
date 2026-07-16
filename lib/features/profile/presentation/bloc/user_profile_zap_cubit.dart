import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/core/domain/entities/zap_status.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/features/profile/domain/entities/user_profile.dart';
import 'package:zapbook/features/profile/domain/usecases/user_profile_usecases.dart';

part 'user_profile_zap_state.dart';

@injectable
class UserProfileZapCubit extends Cubit<UserProfileZapState> {
  UserProfileZapCubit(this._sendProfileZap)
    : super(const UserProfileZapInitial());

  final SendProfileZapUseCase _sendProfileZap;

  Future<void> sendZap({
    required UserProfile profile,
    required ZapGesture gesture,
    int? customSats,
    String? comment,
  }) async {
    emit(UserProfileZapLoading(gesture));

    try {
      await _sendProfileZap(
        profile: profile,
        gesture: gesture,
        customSats: customSats,
        comment: comment,
      );

      emit(
        UserProfileZapSuccess(
          amountSats: gesture.sats ?? customSats ?? 0,
          profileLabel: profile.displayName,
        ),
      );
    } on Exception catch (error) {
      if (error is ZapException) {
        emit(UserProfileZapFailure(error.message));
      } else {
        emit(UserProfileZapFailure(error.toString()));
      }
    } on Object {
      emit(UserProfileZapFailure('Could not zap ${profile.displayName}'));
    }
  }
}
