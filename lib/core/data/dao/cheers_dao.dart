import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;

import 'package:zapbook/core/data/app_database.dart';
import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';

@lazySingleton
class CheersDao {
  CheersDao(this._appDatabase);

  final AppDatabase _appDatabase;
  final _log = logging.Logger('CheersDao');
  
  final _changeController = StreamController<void>.broadcast();

  Stream<List<CheersActivity>> watchActivities() {
    late StreamController<List<CheersActivity>> controller;
    
    Future<void> emit() async {
      final activities = await loadActivities();
      if (!controller.isClosed) {
        controller.add(activities);
      }
    }

    controller = StreamController<List<CheersActivity>>.broadcast(
      onListen: emit,
    );

    final sub = _changeController.stream.listen((_) => emit());
    
    controller.onCancel = () {
      sub.cancel();
      controller.close();
    };

    return controller.stream;
  }

  Future<List<CheersActivity>> loadActivities({int limit = 300}) async {
    try {
      final db = await _appDatabase.open();
      final rows = db.select(
        'SELECT * FROM cheers_feed ORDER BY timestamp DESC LIMIT ?',
        [limit],
      );
      
      return rows.map((row) {
        return CheersActivity(
          id: row['id'] as String,
          actorNpub: row['actor_npub'] as String,
          actorName: row['actor_name'] as String,
          actorAvatar: row['actor_avatar'] as String?,
          bookTitle: row['book_title'] as String,
          bookId: row['book_id'] as String?,
          activityDescription: row['activity_description'] as String,
          timestamp: DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
          type: row['type'] as String,
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

  Future<void> saveActivity(CheersActivity activity) async {
    try {
      final db = await _appDatabase.open();
      db.execute(
        '''
        INSERT OR REPLACE INTO cheers_feed (
          id, actor_npub, actor_name, actor_avatar, book_title, book_id, 
          activity_description, timestamp, type, is_unread, nudge_id, 
          thumbs_up_count, clap_count, fire_count, rocket_count, trophy_count, 
          zap_amount, zap_reaction, zap_target_id, zap_target_description, zap_recipient_npub
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          activity.id,
          activity.actorNpub,
          activity.actorName,
          activity.actorAvatar,
          activity.bookTitle,
          activity.bookId,
          activity.activityDescription,
          activity.timestamp.millisecondsSinceEpoch,
          activity.type,
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
