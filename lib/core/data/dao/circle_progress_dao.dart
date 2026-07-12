import 'dart:async';
import 'package:collection/collection.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:zapbook/core/data/app_database.dart';
import 'package:zapbook/core/models/circle_member_progress.dart';

@lazySingleton
class CircleProgressDao {
  final AppDatabase _db;
  final _changeController = StreamController<void>.broadcast();
  final _log = logging.Logger('CircleProgressDao');

  CircleProgressDao(this._db);

  Future<void> upsertProgress(CircleMemberProgress? progress) async {
    if (progress == null) return;
    try {
      final database = await _db.open();
      final stmt = database.prepare('''
        INSERT INTO circle_member_progress (
          group_id, pub_key, book_id, page_index, progress_percentage,
          updated_at, milestones_reached, completed
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(group_id, pub_key, book_id) DO UPDATE SET
          page_index = excluded.page_index,
          progress_percentage = excluded.progress_percentage,
          updated_at = excluded.updated_at,
          milestones_reached = MAX(excluded.milestones_reached, circle_member_progress.milestones_reached),
          completed = MAX(excluded.completed, circle_member_progress.completed)
        WHERE excluded.updated_at > circle_member_progress.updated_at
      ''');

      stmt.execute([
        progress.groupId,
        progress.pubKey,
        progress.bookId,
        progress.pageIndex,
        progress.progressPercentage,
        progress.updatedAt,
        progress.milestonesReached,
        progress.completed ? 1 : 0,
      ]);

      stmt.close();
      _changeController.add(null);
    } on Object catch (error, stack) {
      _log.warning('Failed to upsert progress', error, stack);
    }
  }

  Stream<List<CircleMemberProgress>> watchProgressByBook({
    required String groupId,
    required String bookId,
  }) {
    late StreamController<List<CircleMemberProgress>> controller;

    Future<void> emit() async {
      try {
        final database = await _db.open();
        final resultSet = database.select(
          '''
          SELECT * FROM circle_member_progress
          WHERE group_id = ? AND book_id = ?
          ORDER BY updated_at DESC
          ''',
          [groupId, bookId],
        );

        if (!controller.isClosed) {
          controller.add(
            resultSet.map((row) => CircleMemberProgress.fromRow(row)).toList(),
          );
        }
      } catch (e) {
        _log.warning('Failed to load progress for book $bookId', e);
      }
    }

    controller = StreamController<List<CircleMemberProgress>>.broadcast(
      onListen: emit,
    );

    final sub = _changeController.stream.listen((_) => emit());

    controller.onCancel = () {
      sub.cancel();
      controller.close();
    };

    const listEquality = ListEquality<CircleMemberProgress>();
    return controller.stream.distinct(listEquality.equals);
  }

  Stream<List<CircleMemberProgress>> watchAllProgressByGroupId(String groupId) {
    late StreamController<List<CircleMemberProgress>> controller;

    Future<void> emit() async {
      try {
        final database = await _db.open();
        final resultSet = database.select(
          '''
          SELECT * FROM circle_member_progress
          WHERE group_id = ?
          ORDER BY updated_at DESC
          ''',
          [groupId],
        );

        if (!controller.isClosed) {
          controller.add(
            resultSet.map((row) => CircleMemberProgress.fromRow(row)).toList(),
          );
        }
      } catch (e) {
        _log.warning('Failed to load progress for group $groupId', e);
      }
    }

    controller = StreamController<List<CircleMemberProgress>>.broadcast(
      onListen: emit,
    );

    final sub = _changeController.stream.listen((_) => emit());

    controller.onCancel = () {
      sub.cancel();
      controller.close();
    };

    const listEquality = ListEquality<CircleMemberProgress>();
    return controller.stream.distinct(listEquality.equals);
  }

  Stream<CircleMemberProgress?> watchMyProgress({
    required String groupId,
    required String bookId,
    required String myNpub,
  }) {
    late StreamController<CircleMemberProgress?> controller;

    Future<void> emit() async {
      try {
        final database = await _db.open();
        final resultSet = database.select(
          '''
          SELECT * FROM circle_member_progress
          WHERE group_id = ? AND book_id = ? AND pub_key = ?
          ''',
          [groupId, bookId, myNpub],
        );

        if (!controller.isClosed) {
          controller.add(
            resultSet.isNotEmpty
                ? CircleMemberProgress.fromRow(resultSet.first)
                : null,
          );
        }
      } catch (e) {
        _log.warning('Failed to load my progress for $groupId/$bookId', e);
      }
    }

    controller = StreamController<CircleMemberProgress?>.broadcast(
      onListen: emit,
    );

    final sub = _changeController.stream.listen((_) => emit());

    controller.onCancel = () {
      sub.cancel();
      controller.close();
    };

    return controller.stream.distinct();
  }

  Future<CircleMemberProgress?> getProgress({
    required String groupId,
    required String bookId,
    required String pubKey,
  }) async {
    try {
      final database = await _db.open();
      final resultSet = database.select(
        '''
        SELECT * FROM circle_member_progress
        WHERE group_id = ? AND book_id = ? AND pub_key = ?
        ''',
        [groupId, bookId, pubKey],
      );
      if (resultSet.isEmpty) return null;
      return CircleMemberProgress.fromRow(resultSet.first);
    } catch (e) {
      _log.warning('Failed to get progress for $groupId/$bookId', e);
      return null;
    }
  }

  Future<int> countCompletedBooks(String pubKey) async {
    try {
      final database = await _db.open();
      final resultSet = database.select(
        '''
        SELECT COUNT(DISTINCT book_id) AS c FROM circle_member_progress
        WHERE pub_key = ? AND completed = 1
        ''',
        [pubKey],
      );
      return (resultSet.first['c'] as num).toInt();
    } catch (e) {
      _log.warning('Failed to count completed books', e);
      return 0;
    }
  }

  Future<int> sumMilestonesReached(String pubKey) async {
    try {
      final database = await _db.open();
      final resultSet = database.select(
        '''
        SELECT COALESCE(SUM(milestones_reached), 0) AS s
        FROM circle_member_progress
        WHERE pub_key = ?
        ''',
        [pubKey],
      );
      return (resultSet.first['s'] as num).toInt();
    } catch (e) {
      _log.warning('Failed to sum milestones', e);
      return 0;
    }
  }
}
