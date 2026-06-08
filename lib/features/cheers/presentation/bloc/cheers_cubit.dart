import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:zapbook/features/cheers/domain/usecases/send_cheers_zap.dart';
import 'package:zapbook/features/cheers/domain/usecases/watch_cheers_activities.dart';
import 'package:zapbook/features/cheers/presentation/bloc/cheers_state.dart';

@injectable
class CheersCubit extends Cubit<CheersState> {
  CheersCubit(
    this._watchCheersActivities,
    this._sendCheersZap,
  ) : super(const CheersLoading()) {
    _subscribe();
  }

  final WatchCheersActivities _watchCheersActivities;
  final SendCheersZap _sendCheersZap;

  StreamSubscription? _subscription;

  void _subscribe() {
    _subscription = _watchCheersActivities().listen(
      (activities) => emit(CheersLoaded(activities)),
      onError: (Object error) => emit(CheersError(error.toString())),
    );
  }

  Future<void> sendZap({
    required String activityId,
    required int amount,
    required String reactionType,
  }) async {
    try {
      await _sendCheersZap(
        activityId: activityId,
        amount: amount,
        reactionType: reactionType,
      );
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
