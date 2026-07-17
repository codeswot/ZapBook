import 'package:zapbook/core/domain/entities/cheers_activity_type.dart';
import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;

import 'package:zapbook/core/data/database/app_database.dart';
import 'package:zapbook/core/domain/entities/cheers_activity_message.dart';

@lazySingleton
class CheersDao {
  CheersDao(this._appDatabase);

  final AppDatabase _appDatabase;
  final _log = logging.Logger('CheersDao');

  final _changeController = StreamController<void>.broadcast();

  Stream<List<CheersActivityMessage>> watchActivities(String ownerNpub) {
    late StreamController<List<CheersActivityMessage>> controller;

    Future<void> emit() async {
      final activities = await loadActivities(ownerNpub);
      if (!controller.isClosed) {
        controller.add(activities);
      }
    }

    controller = StreamController<List<CheersActivityMessage>>.broadcast(
      onListen: emit,
    );

    final sub = _changeController.stream.listen((_) => emit());

    controller.onCancel = () {
      sub.cancel();
      controller.close();
    };

    return controller.stream;
  }

  Future<List<CheersActivityMessage>> loadActivities(
    String ownerNpub, {
    int limit = 300,
  }) async {
    try {
      final db = await _appDatabase.open();
      final rows = db.select(
        '''
        SELECT * FROM cheers_feed
        WHERE owner_npub = ?
          AND NOT (type = ? AND actor_npub = owner_npub)
        ORDER BY timestamp DESC LIMIT ?
        ''',
        [ownerNpub, CheersActivityType.zapNudge.value, limit],
      );

      return rows.map((row) {
        return CheersActivityMessage(
          id: row['id'] as String,
          actorNpub: row['actor_npub'] as String,
          circleBookId: row['book_id'] as String?,
          groupId: row['group_id'] as String?,
          bookTitle: row['book_title'] as String?,
          activityDescription: row['activity_description'] as String,
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            row['timestamp'] as int,
          ),
          type: CheersActivityType.fromString(row['type'] as String),
          isUnread: (row['is_unread'] as int) == 1,
          nudgeId: row['nudge_id'] as String?,
          thumbsUpCount: row['thumbs_up_count'] as int,
          clapCount: row['clap_count'] as int,
          fireCount: row['fire_count'] as int,
          rocketCount: row['rocket_count'] as int,
          trophyCount: row['trophy_count'] as int,
          zapAmount: row['zap_amount'] as int?,
          zapReaction: row['zap_reaction'] as String?,
          zapTargetId: row['zap_target_id'] as String?,
          zapTargetDescription: row['zap_target_description'] as String?,
          zapRecipientNpub: row['zap_recipient_npub'] as String?,
        );
      }).toList();
    } on Object catch (error, stack) {
      _log.warning('Failed to load activities', error, stack);
      return [];
    }
  }

  Future<void> saveActivity(
    String ownerNpub,
    CheersActivityMessage? activity,
  ) async {
    if (activity == null) return;
    try {
      final db = await _appDatabase.open();
      db.execute(
        '''
        INSERT OR REPLACE INTO cheers_feed (
          id, owner_npub, actor_npub, book_id, group_id, book_title,
          activity_description, timestamp, type, is_unread, nudge_id,
          thumbs_up_count, clap_count, fire_count, rocket_count, trophy_count,
          zap_amount, zap_reaction, zap_target_id, zap_target_description, zap_recipient_npub
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          activity.id,
          ownerNpub,
          activity.actorNpub,
          activity.circleBookId,
          activity.groupId,
          activity.bookTitle,
          activity.activityDescription,
          activity.timestamp.millisecondsSinceEpoch,
          activity.type.value,
          activity.isUnread ? 1 : 0,
          activity.nudgeId,
          activity.thumbsUpCount,
          activity.clapCount,
          activity.fireCount,
          activity.rocketCount,
          activity.trophyCount,
          activity.zapAmount,
          activity.zapReaction,
          activity.zapTargetId,
          activity.zapTargetDescription,
          activity.zapRecipientNpub,
        ],
      );
      _changeController.add(null);
    } on Object catch (error, stack) {
      _log.warning('Failed to save activity', error, stack);
    }
  }
}
