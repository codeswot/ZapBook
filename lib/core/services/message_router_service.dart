import 'dart:async';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:zapbook/core/models/app_message.dart';
import 'package:zapbook/core/services/marmot_sync_service.dart';
import 'package:zapbook/core/data/dao/cheers_dao.dart';
import 'package:zapbook/core/data/dao/circle_progress_dao.dart';
import 'package:zapbook/core/domain/entities/cheers_activity_message.dart';
import 'package:zapbook/core/models/circle_member_progress.dart';

@LazySingleton()
class MessageRouterService {
  final MarmotSyncService _marmotSyncService;
  final CheersDao _cheersDao;
  final CircleProgressDao _circleProgressDao;

  final _log = logging.Logger('MessageRouterService');
  StreamSubscription<MarmotMessage>? _messageSub;

  MessageRouterService(
    this._marmotSyncService,
    this._cheersDao,
    this._circleProgressDao,
  ) {
    initialize();
  }

  void initialize() {
    _messageSub ??= _marmotSyncService.onMessage.listen(
      _handleRawMessage,
      onError: (Object error, StackTrace stack) {
        _log.warning('Message stream error', error, stack);
      },
    );
  }

  Future<void> _handleRawMessage(MarmotMessage rawMsg) async {
    final parsed = AppMessage.tryParse(rawMsg);
    _log.warning('Incoming Message ${parsed.runtimeType}');
    if (parsed == null) return;

    try {
      switch (parsed) {
        case BookProgressMessage():
          final next = CircleMemberProgress.fromAppMessage(parsed);
          final previous = await _circleProgressDao.getProgress(
            groupId: next.groupId,
            bookId: next.bookId,
            pubKey: next.pubKey,
          );
          await _circleProgressDao.upsertProgress(next);

          final cheer = CheersActivityMessage.cheerFromProgress(
            id: parsed.id,
            actorNpub: parsed.senderNpub,
            groupId: parsed.groupId,
            timestampSecs: parsed.timestampSecs,
            previous: previous,
            next: next,
          );
          if (cheer != null) {
            await _cheersDao.saveActivity(cheer);
          }

        case CheersMessage() ||
            ZapSentMessage() ||
            ZapNudgeMessage() ||
            ZapReadyMessage():
          final activity = CheersActivityMessage.fromAppMessage(parsed);
          await _cheersDao.saveActivity(activity);

        case InitialBookMessage() || BookCompletedMessage():
          break;
      }
    } on Object catch (error, stack) {
      _log.warning('Failed to route message ${rawMsg.id}', error, stack);
    }
  }

  void dispose() {
    _messageSub?.cancel();
    _messageSub = null;
  }
}
