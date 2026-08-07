import 'dart:async';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:zapbook/core/domain/entities/app_message.dart';
import 'package:zapbook/core/data/infrastructure/marmot_sync_service.dart';
import 'package:zapbook/core/data/database/dao/cheers_dao.dart';
import 'package:zapbook/core/data/database/dao/circle_progress_dao.dart';
import 'package:zapbook/core/domain/entities/cheers_activity_message.dart';
import 'package:zapbook/core/models/circle_member_progress.dart';
import 'package:zapbook/core/domain/book_group_naming.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/features/circles/domain/repositories/circles_repository.dart';

@LazySingleton()
class MessageRouterService {
  final MarmotSyncService _marmotSyncService;
  final CheersDao _cheersDao;
  final CircleProgressDao _circleProgressDao;
  final IdentityLocalDataSource _identityLocalDataSource;
  final CirclesRepository _circlesRepository;
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
    this._identityLocalDataSource,
    this._circlesRepository,
    this._marmot,
  ) {
    initialize();
  }

  void initialize() {
    _messageSub ??= _marmotSyncService.onMessage.listen(
      _handleRawMessage,
      onError: (Object error, StackTrace stack) =>
          _log.warning('Message stream error', error, stack),
    );
  }

  void dispose() {
    _messageSub?.cancel();
    _messageSub = null;
  }

  Future<void> _handleRawMessage(MarmotMessage rawMsg) async {
    final parsed = AppMessage.tryParse(rawMsg);
    if (parsed == null) return;

    _log.fine('Routing incoming message: ${parsed.runtimeType}');

    final npub = await _identityLocalDataSource.readNpub();
    if (npub == null) return;

    try {
      final activity = await _processAndCreateActivity(parsed, npub);
      if (activity != null) {
        await _cheersDao.saveActivity(npub, activity);
        _activityController.add(activity);
      }
    } on Object catch (error, stack) {
      _log.warning('Failed to route message ${rawMsg.id}', error, stack);
    }
  }

  Future<CheersActivityMessage?> _processAndCreateActivity(
    AppMessage message,
    String currentNpub,
  ) async {
    final bookTitle = await _titleFor(message.groupId);

    switch (message) {
      case BookProgressMessage():
        return _handleBookProgress(message, currentNpub, bookTitle);

      case ReseedRequestMessage():
        return _handleReseedRequest(message, currentNpub, bookTitle);

      case CheersMessage() || ZapSentMessage():
        if (message.senderNpub == currentNpub) return null;
        return CheersActivityMessage.fromAppMessage(
          message,
          bookTitle: bookTitle,
        );

      case ZapNudgeMessage(:final toNpub) || ZapReadyMessage(:final toNpub):
        if (toNpub != currentNpub) return null;
        return CheersActivityMessage.fromAppMessage(
          message,
          bookTitle: bookTitle,
        );

      case InitialBookMessage() || BookCompletedMessage():
        return null;
    }
  }

  Future<CheersActivityMessage?> _handleBookProgress(
    BookProgressMessage message,
    String currentNpub,
    String? bookTitle,
  ) async {
    final next = CircleMemberProgress.fromAppMessage(message);
    final previous = await _circleProgressDao.getProgress(
      groupId: next.groupId,
      bookId: next.bookId,
      pubKey: next.pubKey,
    );

    await _circleProgressDao.upsertProgress(next);

    if (message.senderNpub == currentNpub) return null;

    return CheersActivityMessage.cheerFromProgress(
      id: message.id,
      actorNpub: message.senderNpub,
      groupId: message.groupId,
      timestampSecs: message.timestampSecs,
      previous: previous,
      next: next,
      bookTitle: bookTitle,
    );
  }

  Future<CheersActivityMessage?> _handleReseedRequest(
    ReseedRequestMessage message,
    String currentNpub,
    String? bookTitle,
  ) async {
    if (message.senderNpub == currentNpub) return null;

    final group = await _marmot.getGroup(message.groupId);
    if (group == null || !group.adminNpubs.contains(currentNpub)) return null;

    return CheersActivityMessage.fromAppMessage(message, bookTitle: bookTitle);
  }

  Future<String?> _titleFor(String? groupId) async {
    if (groupId == null || groupId.isEmpty) return null;

    if (_groupTitles.containsKey(groupId)) {
      return _groupTitles[groupId];
    }

    try {
      final group = await _marmot.getGroup(groupId);
      if (group == null) return null;

      final title = BookGroupNaming.matches(group.name)
          ? BookGroupNaming.titleOf(group.name)
          : group.name;

      _groupTitles[groupId] = title;
      return title;
    } on Object catch (error) {
      _log.fine('Title lookup failed for $groupId: $error');
      return null;
    }
  }
}
