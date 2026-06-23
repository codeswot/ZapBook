import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:ndk/ndk.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/services/nostr_service.dart';
import 'package:zapbook/core/services/zap_nudge_service.dart';
import 'package:zapbook/core/services/zap_service.dart';
import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';
import 'package:zapbook/features/cheers/domain/usecases/send_cheers_zap.dart';
import 'package:zapbook/features/cheers/domain/usecases/watch_cheers_activities.dart';
import 'package:zapbook/features/cheers/domain/usecases/load_more_cheers_activities.dart';
import 'package:zapbook/features/cheers/presentation/bloc/cheers_state.dart';

@injectable
class CheersCubit extends Cubit<CheersState> {
  CheersCubit(
    this._watchCheersActivities,
    this._sendCheersZap,
    this._loadMoreCheersActivities,
    this._zapService,
    this._nudgeService,
    this._nostrService,
  ) : super(const CheersLoading()) {
    _subscribe();
  }

  final WatchCheersActivities _watchCheersActivities;
  final SendCheersZap _sendCheersZap;
  final LoadMoreCheersActivities _loadMoreCheersActivities;
  final ZapService _zapService;
  final ZapNudgeService _nudgeService;
  final NostrService _nostrService;

  final _log = logging.Logger('CheersCubit');
  StreamSubscription? _subscription;
  Timer? _debounceTimer;

  List<CheersActivity> _rawActivities = [];
  String _activeFilter = 'All';

  void _subscribe() {
    _subscription = _watchCheersActivities().listen((activities) {
      _rawActivities = activities;
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 250), () {
        _emitFiltered();
      });
    }, onError: (Object error) => emit(CheersError(error.toString())));
  }

  void loadMore() {
    _loadMoreCheersActivities();
  }

  void setFilter(String filter) {
    if (_activeFilter == filter) return;
    _activeFilter = filter;
    if (_rawActivities.isNotEmpty) {
      _emitFiltered();
    }
  }

  void _emitFiltered() {
    final visible = _rawActivities.where((a) => a.type != 'zap_ready');
    List<CheersActivity> filtered;

    if (_activeFilter == 'All') {
      filtered = visible.toList();
    } else if (_activeFilter == 'Milestones') {
      filtered = visible
          .where((a) => a.type == 'milestone' || a.type == 'notification')
          .toList();
    } else if (_activeFilter == 'Zaps') {
      filtered = visible.where((a) {
        if (a.type != 'zap') return false;
        return a.actorName == 'You' || a.zapRecipientNpub != null;
      }).toList();
    } else if (_activeFilter == 'Notification') {
      filtered = visible.where((a) => a.type == 'notification').toList();
    } else {
      filtered = visible.toList();
    }

    emit(CheersLoaded(activities: filtered, activeFilter: _activeFilter));
  }

  Future<void> performZap({
    required CheersActivity activity,
    required ZapGesture gesture,
    required int amount,
    String? comment,
  }) async {
    if (activity.type == 'mine') return;

    final reactionType = gesture.id;

    try {
      await _sendCheersZap(
        activityId: activity.id,
        amount: amount,
        reactionType: reactionType,
      );
    } on Object catch (error, stack) {
      _log.warning('Send cheers reaction failed', error, stack);
      emit(const CheersZapError('Failed to send reaction'));
      return;
    }

    try {
      final pubkey = Nip19.decode(activity.actorNpub);
      final lud16 = await _lookupLud16(pubkey);
      if (lud16 != null && lud16.isNotEmpty) {
        final result = await _externalZap(
          recipientLud16: lud16,
          recipientPubkey: pubkey,
          gesture: gesture,
          amount: amount,
          comment: comment,
          circleId: activity.bookId,
        );
        final supportMsg = result.hasSupportZap
            ? ' (+${result.supportAmount} to ZapBook)'
            : '';
        await _payZap(result);
        emit(
          CheersZapSuccess(
            'Zapping $amount sats to ${activity.actorName}$supportMsg',
          ),
        );
      } else {
        await _nudge(
          groupId: activity.id.split(':').first,
          toNpub: activity.actorNpub,
        );
        emit(
          CheersNudgeRequired(
            activity,
            "${activity.actorName} can't be zapped yet",
            "${activity.actorName} hasn't set up their lightning wallet. "
                "We've let them know — you'll get a heads-up here when they're "
                'ready.',
          ),
        );
      }
    } catch (_) {
      emit(CheersZapInfo('Reacted with ${gesture.emoji}!'));
    }
  }

  Future<void> performNudge(CheersActivity activity) async {
    final lud16 = await _getMyLud16();

    if (lud16 == null || lud16.isEmpty) {
      emit(
        CheersNudgeSetupRequired(
          activity,
          'Set up your wallet',
          '${activity.actorName} wants to zap you. Add your lightning '
              'address in your profile to receive it, then come back and tap '
              'this card to buzz them.',
        ),
      );
      return;
    }

    try {
      await _nudgeReady(
        groupId: activity.id.split(':').first,
        nudgeId: activity.nudgeId ?? '',
        toNpub: activity.actorNpub,
      );
      emit(
        CheersNudgeSuccess("Buzzed ${activity.actorName} — you're all set!"),
      );
    } catch (error, stack) {
      _log.warning('Nudge ready failed', error, stack);
      emit(const CheersZapError('Failed to send buzz'));
    }
  }

  Future<ZapResult> _externalZap({
    required String recipientLud16,
    required String recipientPubkey,
    required ZapGesture gesture,
    required int amount,
    String? comment,
    String? circleId,
  }) => _zapService.send(
    recipientLud16: recipientLud16,
    recipientPubkey: recipientPubkey,
    targetEventId: '',
    gesture: gesture,
    customSats: amount,
    comment: comment,
    circleId: circleId,
  );

  Future<bool> _payZap(ZapResult result) => _zapService.payZap(result);

  Future<void> _nudge({required String groupId, required String toNpub}) =>
      _nudgeService.nudge(groupId: groupId, toNpub: toNpub);

  Future<void> _nudgeReady({
    required String groupId,
    required String nudgeId,
    required String toNpub,
  }) => _nudgeService.ready(groupId: groupId, nudgeId: nudgeId, toNpub: toNpub);

  Future<String?> _lookupLud16(String pubkey) async {
    final cache = await _nostrService.getMetadata(pubkey);
    final cachedlud16 = cache?.lud16 ?? '';
    if (cachedlud16.isNotEmpty) {
      return cachedlud16;
    }
    final fresh = await _nostrService.getMetadata(pubkey, forceRefresh: true);
    return fresh?.lud16;
  }

  Future<String?> _getMyLud16() async {
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
