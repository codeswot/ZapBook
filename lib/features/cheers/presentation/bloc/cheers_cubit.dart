import 'package:zapbook/core/domain/entities/cheers_activity_type.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:ndk/ndk.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/services/clipboard_service.dart';
import 'package:zapbook/core/services/nostr_service.dart';
import 'package:zapbook/core/services/zap_nudge_service.dart';
import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';
import 'package:zapbook/features/cheers/domain/usecases/watch_cheers_activities.dart';

import 'package:zapbook/core/data/dao/zap_sats_earnings_dao.dart';
import 'package:zapbook/core/services/zap_service.dart';

import 'package:zapbook/features/cheers/presentation/bloc/cheers_state.dart';

@injectable
class CheersCubit extends Cubit<CheersState> {
  CheersCubit(
    this._watchCheersActivities,
    this._nudgeService,
    this._nostrService,
    this._zapService,
    this._clipboardService,
  ) : super(const CheersLoading()) {
    _subscribe();
  }

  final WatchCheersActivities _watchCheersActivities;
  final ZapNudgeService _nudgeService;
  final NostrService _nostrService;
  final ZapService _zapService;
  final ClipboardService _clipboardService;

  final _log = logging.Logger('CheersCubit');
  StreamSubscription? _subscription;

  List<CheersActivity> _rawActivities = [];
  String _activeFilter = 'All';

  void _subscribe() {
    _subscription = _watchCheersActivities().listen((activities) {
      _rawActivities = activities;
      _emitFiltered();
    }, onError: (Object error) => emit(CheersError(error.toString())));
  }

  void setFilter(String filter) {
    if (_activeFilter == filter) return;
    _activeFilter = filter;
    if (_rawActivities.isNotEmpty) {
      _emitFiltered();
    }
  }

  void _emitFiltered() {
    final filtered = <CheersActivity>[];

    for (final a in _rawActivities) {
      if (a.type == CheersActivityType.zapReady) continue;

      switch (_activeFilter) {
        case 'Milestones':
          if (a.type == CheersActivityType.milestone ||
              a.type == CheersActivityType.notification) {
            filtered.add(a);
          }
          break;
        case 'Zaps':
          if (a.type == CheersActivityType.zap &&
              (a.isMine || a.recipientNpub.isNotEmpty)) {
            filtered.add(a);
          }
          break;
        case 'Notification':
          if (a.type == CheersActivityType.notification) {
            filtered.add(a);
          }
          break;
        case 'All':
        default:
          filtered.add(a);
          break;
      }
    }

    emit(CheersLoaded(activities: filtered, activeFilter: _activeFilter));
  }

  Future<void> performZap({
    required CheersActivity activity,
    required ZapGesture gesture,
    required int amount,

    String? comment,
  }) async {
    if (activity.isMine) return;

    try {
      final pubkey = Nip19.decode(activity.recipientNpub);
      final lud16 = await _lookupLud16(pubkey);

      if (lud16 == null || lud16.isEmpty) {
        unawaited(
          _nudge(groupId: activity.groupId, toNpub: activity.recipientNpub),
        );
        emit(
          CheersNudgeRequired(
            activity,
            "${activity.otherPartyName} can't be zapped yet",
            "${activity.otherPartyName} hasn't set up their lightning wallet. "
                "We've let them know — you'll get a heads-up here when they're ready.",
          ),
        );
        return;
      }

      final result = await _zapService.send(
        recipientLud16: lud16,
        recipientPubkey: pubkey,
        targetActivitytId: activity.targetId,
        gesture: gesture,
        customSats: amount,
        comment: comment,
        zapType: activity.type == CheersActivityType.milestone
            ? ZapType.milestone
            : ZapType.profile,
      );

      final status = await _zapService.payZap(result);
      if (status == ZapStatus.paidNwc) {
        emit(
          CheersZapSuccess('Zapped ${activity.otherPartyName} $amount sats!'),
        );
      } else if (status == ZapStatus.failed) {
        emit(
          CheersZapSuccess(
            'Failed to Zap ${activity.otherPartyName} $amount sats!',
          ),
        );
      } else {
        emit(CheersZapSuccess('Zapping in progress'));
      }
    } catch (e, st) {
      _log.warning('failed to zap', e, st);
      if (e is ZapException) {
        emit(CheersZapError(e.message));
      } else {
        emit(CheersZapError('Failed to zap ${activity.otherPartyName}'));
      }
    }
  }

  Future<void> performNudge(CheersActivity activity) async {
    final pubkey = _nostrService.pubkey;
    if (pubkey == null) return;
    final lud16 = await _lookupLud16(pubkey);

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
        groupId: activity.groupId,
        nudgeId: activity.nudgeId ?? '',
        toNpub: activity.senderNpub,
      );
      emit(
        CheersNudgeSuccess("Buzzed ${activity.actorName} — you're all set!"),
      );
    } catch (error, stack) {
      _log.warning('Nudge ready failed', error, stack);
      emit(const CheersZapError('Failed to send buzz'));
    }
  }

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

  Future<void> copyActivityToClipboard(CheersActivity activity) async {
    _clipboardService.copy(
      '${activity.actorName}: ${activity.targetDescription}',
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
