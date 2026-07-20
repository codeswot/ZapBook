import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;

import 'package:zapbook/core/data/database/app_database.dart';

@lazySingleton
class CircleReseedAckDao {
  CircleReseedAckDao(this._db);

  final AppDatabase _db;
  final _log = logging.Logger('CircleReseedAckDao');

  Future<DateTime?> lastAck(String circleDirId) async {
    try {
      final database = await _db.open();
      final rows = database.select(
        'SELECT acked_at FROM circle_reseed_acks WHERE circle_dir_id = ?',
        [circleDirId],
      );
      if (rows.isEmpty) return null;
      return DateTime.fromMillisecondsSinceEpoch(
        (rows.first['acked_at'] as num).toInt(),
      );
    } on Object catch (error, stack) {
      _log.warning('Failed to read reseed ack for $circleDirId', error, stack);
      return null;
    }
  }

  Future<void> ack(String circleDirId) async {
    try {
      final database = await _db.open();
      database.execute(
        '''
        INSERT INTO circle_reseed_acks (circle_dir_id, acked_at)
        VALUES (?, ?)
        ON CONFLICT(circle_dir_id) DO UPDATE SET acked_at = excluded.acked_at
        ''',
        [circleDirId, DateTime.now().millisecondsSinceEpoch],
      );
    } on Object catch (error, stack) {
      _log.warning('Failed to ack reseed for $circleDirId', error, stack);
    }
  }
}
