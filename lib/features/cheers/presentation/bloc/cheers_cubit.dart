import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/services/nostr_service.dart';
import 'package:zapbook/core/services/zap_nudge_service.dart';
import 'package:zapbook/core/services/zap_service.dart';
import 'package:zapbook/features/cheers/domain/usecases/send_cheers_zap.dart';
import 'package:zapbook/features/cheers/domain/usecases/watch_cheers_activities.dart';
import 'package:zapbook/features/cheers/presentation/bloc/cheers_state.dart';

@injectable
class CheersCubit extends Cubit<CheersState> {
  CheersCubit(
    this._watchCheersActivities,
    this._sendCheersZap,
    this._zapService,
    this._nudgeService,
    this._nostrService,
  ) : super(const CheersLoading()) {
    _subscribe();
  }

  final WatchCheersActivities _watchCheersActivities;
  final SendCheersZap _sendCheersZap;
  final ZapService _zapService;
  final ZapNudgeService _nudgeService;
  final NostrService _nostrService;

  final _log = logging.Logger('CheersCubit');
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
    } on Object catch (error, stack) {
      _log.warning('Send cheers reaction failed', error, stack);
    }
  }

  Future<ZapResult> externalZap({
    required String recipientLud16,
    required String recipientPubkey,
    required ZapGesture gesture,
    required int amount,
    String? comment,
  }) => _zapService.send(
    recipientLud16: recipientLud16,
    recipientPubkey: recipientPubkey,
    targetEventId: '',
    gesture: gesture,
    customSats: amount,
    comment: comment,
  );

  Future<bool> payInvoice(String invoice) =>
      _zapService.payWithFallback(invoice);

  Future<void> nudge({required String groupId, required String toNpub}) =>
      _nudgeService.nudge(groupId: groupId, toNpub: toNpub);

  Future<void> nudgeReady({
    required String groupId,
    required String nudgeId,
    required String toNpub,
  }) => _nudgeService.ready(groupId: groupId, nudgeId: nudgeId, toNpub: toNpub);

  Future<String?> lookupLud16(String pubkey) async {
    final cache = await _nostrService.getMetadata(pubkey);
    final cachedlud16 = cache?.lud16 ?? '';
    if (cachedlud16.isNotEmpty) {
      return cachedlud16;
    }
    final fresh = await _nostrService.getMetadata(pubkey, forceRefresh: true);
    return fresh?.lud16;
  }

  Future<String?> getMyLud16() async {
    final pubkey = _nostrService.pubkey;
    if (pubkey == null) return null;
    final meta = await _nostrService.getMetadata(pubkey);
    return meta?.lud16;
  }

  String? get myPubkey => _nostrService.pubkey;

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
