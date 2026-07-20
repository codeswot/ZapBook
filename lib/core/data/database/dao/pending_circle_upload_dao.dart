import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;

import 'package:zapbook/core/data/database/app_database.dart';
import 'package:zapbook/core/domain/entities/pending_circle_upload.dart';

@lazySingleton
class PendingCircleUploadDao {
  PendingCircleUploadDao(this._db);

  final AppDatabase _db;
  final _log = logging.Logger('PendingCircleUploadDao');
  final _changeController = StreamController<void>.broadcast();

  Stream<List<PendingCircleUpload>> watchAll(String ownerNpub) {
    late StreamController<List<PendingCircleUpload>> controller;

    Future<void> emit() async {
      final rows = await loadAll(ownerNpub);
      if (!controller.isClosed) controller.add(rows);
    }

    controller = StreamController<List<PendingCircleUpload>>.broadcast(
      onListen: emit,
    );
    final sub = _changeController.stream.listen((_) => emit());
    controller.onCancel = () {
      sub.cancel();
      controller.close();
    };

    return controller.stream;
  }

  Future<List<PendingCircleUpload>> loadAll(String ownerNpub) async {
    try {
      final database = await _db.open();
      final rows = database.select(
        'SELECT * FROM pending_circle_uploads WHERE owner_npub = ? ORDER BY updated_at DESC',
        [ownerNpub],
      );
      return rows.map(_fromRow).toList();
    } on Object catch (error, stack) {
      _log.warning('Failed to load pending circle uploads', error, stack);
      return [];
    }
  }

  Future<void> markFailed({
    required String circleDirId,
    required String groupId,
    required String ownerNpub,
    required int attempts,
    String? reason,
  }) async {
    try {
      final database = await _db.open();
      database.execute(
        '''
        INSERT INTO pending_circle_uploads (
          circle_dir_id, group_id, owner_npub, attempts, failure_reason, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?)
        ON CONFLICT(circle_dir_id) DO UPDATE SET
          attempts = excluded.attempts,
          failure_reason = excluded.failure_reason,
          updated_at = excluded.updated_at
        ''',
        [
          circleDirId,
          groupId,
          ownerNpub,
          attempts,
          reason,
          DateTime.now().millisecondsSinceEpoch,
        ],
      );
      _changeController.add(null);
    } on Object catch (error, stack) {
      _log.warning('Failed to record pending circle upload', error, stack);
    }
  }

  Future<void> clear(String circleDirId) async {
    try {
      final database = await _db.open();
      database.execute(
        'DELETE FROM pending_circle_uploads WHERE circle_dir_id = ?',
        [circleDirId],
      );
      _changeController.add(null);
    } on Object catch (error, stack) {
      _log.warning('Failed to clear pending circle upload', error, stack);
    }
  }

  PendingCircleUpload _fromRow(Map<String, dynamic> row) {
    return PendingCircleUpload(
      circleDirId: row['circle_dir_id'] as String,
      groupId: row['group_id'] as String,
      ownerNpub: row['owner_npub'] as String,
      attempts: (row['attempts'] as num).toInt(),
      failureReason: row['failure_reason'] as String?,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (row['updated_at'] as num).toInt(),
      ),
    );
  }
}
