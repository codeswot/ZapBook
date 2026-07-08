import 'dart:async';
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

  Future<void> upsertProgress(CircleMemberProgress progress) async {
    try {
      final database = await _db.open();
      final stmt = database.prepare('''
        INSERT INTO circle_member_progress (
          group_id, pub_key, book_id, page_index, progress_percentage, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?)
        ON CONFLICT(group_id, pub_key, book_id) DO UPDATE SET
          page_index = excluded.page_index,
          progress_percentage = excluded.progress_percentage,
          updated_at = excluded.updated_at
        WHERE excluded.updated_at > circle_member_progress.updated_at
      ''');

      stmt.execute([
        progress.groupId,
        progress.pubKey,
        progress.bookId,
        progress.pageIndex,
        progress.progressPercentage,
        progress.updatedAt,
      ]);

      stmt.close();
      _changeController.add(null);
    } on Object catch (error, stack) {
      _log.warning('Failed to upsert progress', error, stack);
    }
  }

  Stream<List<CircleMemberProgress>> watchProgress(String groupId) {
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

    return controller.stream;
  }
}
