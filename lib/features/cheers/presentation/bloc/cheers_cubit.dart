import 'package:zapbook/core/domain/entities/cheers_activity_type.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:ndk/ndk.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/domain/entities/zap_status.dart';
import 'package:zapbook/features/cheers/domain/cheers_note_composer.dart';
import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';
import 'package:zapbook/features/cheers/domain/usecases/cheers_usecases.dart';
import 'package:zapbook/features/cheers/presentation/bloc/cheers_state.dart';

@injectable
class CheersCubit extends Cubit<CheersState> {
  CheersCubit(
    this._watchCheersActivities,
    this._sendCheersZap,
    this._sendCheersNudge,
    this._lookupLud16,
    this._copyText,
    this._shareText,
    this._postNote,
    this._markAsRead,
    this._noteComposer,
  ) : super(const CheersLoading()) {
    _subscribe();
  }

  final WatchCheersActivitiesUseCase _watchCheersActivities;
  final SendCheersZapUseCase _sendCheersZap;
  final SendCheersNudgeUseCase _sendCheersNudge;
  final LookupLud16UseCase _lookupLud16;
  final CopyCheersActivityTextUseCase _copyText;
  final ShareCheersActivityTextUseCase _shareText;
  final PostCheersNoteUseCase _postNote;
  final MarkCheersActivityAsReadUseCase _markAsRead;
  final CheersNoteComposer _noteComposer;

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
              (a.isMine || a.otherPartyNpub.isNotEmpty)) {
            filtered.add(a);
          }
          break;
        case 'Notification':
          if (a.type == CheersActivityType.notification ||
              a.type == CheersActivityType.zapNudge ||
              a.type == CheersActivityType.adminAction) {
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
      final pubkey = Nip19.decode(activity.actorNpub);
      final lud16 = await _lookupLud16(pubkey);

      if (lud16 == null || lud16.isEmpty) {
        unawaited(
          _sendCheersNudge.sendNudge(
            groupId: activity.groupId,
            toNpub: activity.actorNpub,
          ),
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

      final status = await _sendCheersZap(
        activity: activity,
        gesture: gesture,
        amount: amount,
        comment: comment,
      );

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
    final myPubkey = await _sendCheersNudge.getMyPubkey();
    if (myPubkey == null) return;
    final lud16 = await _lookupLud16(myPubkey);

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
      await _sendCheersNudge.sendNudgeReady(
        groupId: activity.groupId,
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

  String noteTextFor(CheersActivity activity) =>
      _noteComposer.compose(activity);

  Future<void> copyActivityToClipboard(CheersActivity activity) async {
    await _copyText(_noteComposer.compose(activity));
  }

  Future<void> shareActivity(CheersActivity activity) async {
    await _shareText(_noteComposer.compose(activity));
  }

  Future<void> postActivityAsNote(CheersActivity activity, String text) async {
    final content = text.trim();
    if (content.isEmpty) {
      emit(const CheersPostError('Note is empty'));
      return;
    }

    final mentions = activity.isMine ? const <String>[] : [activity.actorNpub];

    try {
      await _postNote(content, mentionNpubs: mentions);
      emit(const CheersPostSuccess('Posted to Nostr'));
    } catch (error, stack) {
      _log.warning('Post note failed', error, stack);
      emit(const CheersPostError('Failed to post note'));
    }
  }

  void markAsRead(String activityId) {
    _markAsRead(activityId);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
