import 'dart:async';
import 'dart:convert';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:zapbook/core/domain/entities/app_message.dart';
import 'package:zapbook/core/data/infrastructure/marmot_sync_service.dart';
import 'package:zapbook/core/data/database/dao/book_highlights_dao.dart';
import 'package:zapbook/core/data/database/dao/cheers_dao.dart';
import 'package:zapbook/core/data/database/dao/circle_progress_dao.dart';
import 'package:zapbook/core/domain/entities/cheers_activity_message.dart';
import 'package:zapbook/core/models/circle_member_progress.dart';
import 'package:zapbook/core/domain/book_group_naming.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';

@LazySingleton()
class MessageRouterService {
  final MarmotSyncService _marmotSyncService;
  final CheersDao _cheersDao;
  final CircleProgressDao _circleProgressDao;
  final BookHighlightsDao _bookHighlightsDao;
  final IdentityLocalDataSource _identityLocalDataSource;
  final Marmot _marmot;

  final _log = logging.Logger('MessageRouterService');
  StreamSubscription<MarmotMessage>? _messageSub;

  final _activityController =
      StreamController<CheersActivityMessage>.broadcast();
  Stream<CheersActivityMessage> get onActivity => _activityController.stream;

  final _groupTitles = <String, String>{};

  MessageRouterService(
    this._marmotSyncService,
    this._cheersDao,
    this._circleProgressDao,
    this._bookHighlightsDao,
    this._identityLocalDataSource,
    this._marmot,
  ) {
    initialize();
  }

  Future<String?> _titleFor(String? groupId) async {
    if (groupId == null || groupId.isEmpty) return null;
    final cached = _groupTitles[groupId];
    if (cached != null) return cached;
    try {
      final group = await _marmot.getGroup(groupId);
      if (group == null) return null;
      final title = BookGroupNaming.matches(group.name)
          ? BookGroupNaming.titleOf(group.name)
          : group.name;
      _groupTitles[groupId] = title;
      return title;
    } on Object catch (error) {
      _log.fine('title lookup failed for $groupId: $error');
      return null;
    }
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
            bookTitle: await _titleFor(parsed.groupId),
          );
          if (cheer != null) {
            final npub = await _identityLocalDataSource.readNpub();
            if (npub != null) await _cheersDao.saveActivity(npub, cheer);
            _activityController.add(cheer);
          }

        case CheersMessage() || ZapSentMessage() || ReseedRequestMessage():
          final activity = CheersActivityMessage.fromAppMessage(
            parsed,
            bookTitle: await _titleFor(parsed.groupId),
          );
          final npub = await _identityLocalDataSource.readNpub();
          if (npub != null && activity != null) {
            if (parsed is ReseedRequestMessage) {
              final group = await _marmot.getGroup(parsed.groupId);
              if (group == null || !group.adminNpubs.contains(npub)) {
                break;
              }
            }

            await _cheersDao.saveActivity(npub, activity);
            _activityController.add(activity);
          }

        case ZapNudgeMessage(payload: final payload) ||
            ZapReadyMessage(payload: final payload):
          final npub = await _identityLocalDataSource.readNpub();
          if (npub == null || payload['toNpub'] != npub) break;
          final activity = CheersActivityMessage.fromAppMessage(
            parsed,
            bookTitle: await _titleFor(parsed.groupId),
          );
          if (activity != null) {
            await _cheersDao.saveActivity(npub, activity);
            _activityController.add(activity);
          }

        case HighlightSharedMessage(payload: final payload):
          final id = payload['id'] as String?;
          if (id == null) break;
          if (payload['deleted'] == true) {
            await _bookHighlightsDao.softDelete(id);
            break;
          }
          await _bookHighlightsDao.upsert(
            HighlightRecord(
              id: id,
              bookId: payload['bookId'] as String? ?? '',
              ownerNpub: parsed.senderNpub,
              visibility: 'circle',
              groupId: parsed.groupId,
              pageNumber: (payload['pageNumber'] as num?)?.toInt() ?? 0,
              spansJson: jsonEncode(payload['spans']),
              quoteSnapshot: payload['quoteSnapshot'] as String? ?? '',
              note: payload['note'] as String?,
              createdAt: parsed.timestampSecs * 1000,
              updatedAt:
                  (payload['sharedAtMs'] as num?)?.toInt() ??
                  parsed.timestampSecs * 1000,
            ),
          );

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
