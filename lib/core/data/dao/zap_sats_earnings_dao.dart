import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:zapbook/core/data/app_database.dart';

class ZapSatsEarningsRecord {
  final String id;
  final String senderNpub;
  final String activityId;
  final String zapType;
  final int sats;
  final int timestamp;

  ZapSatsEarningsRecord({
    required this.id,
    required this.senderNpub,
    required this.activityId,
    required this.zapType,
    required this.sats,
    required this.timestamp,
  });

  factory ZapSatsEarningsRecord.fromRow(Map<String, dynamic> row) {
    return ZapSatsEarningsRecord(
      id: row['id'] as String,
      senderNpub: row['sender_npub'] as String,
      activityId: row['activity_id'] as String,
      zapType: row['zap_type'] as String,
      sats: (row['sats'] as num).toInt(),
      timestamp: (row['timestamp'] as num).toInt(),
    );
  }
}

@lazySingleton
class ZapSatsEarningsDao {
  final AppDatabase _db;
  final _changeController = StreamController<void>.broadcast();
  final _log = logging.Logger('ZapSatsEarningsDao');

  ZapSatsEarningsDao(this._db);

  Future<void> insertZap(ZapSatsEarningsRecord record) async {
    try {
      final database = await _db.open();
      final stmt = database.prepare('''
        INSERT INTO zap_sats_earnings (
          id, sender_npub, activity_id, zap_type, sats, timestamp
        ) VALUES (?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO NOTHING
      ''');

      stmt.execute([
        record.id,
        record.senderNpub,
        record.activityId,
        record.zapType,
        record.sats,
        record.timestamp,
      ]);

      if (database.updatedRows > 0) {
        _changeController.add(null);
      }

      stmt.close();
    } on Object catch (error, stack) {
      _log.warning('Failed to insert zap sats earnings', error, stack);
    }
  }

  Future<int> getTotalSats() async {
    try {
      final database = await _db.open();
      final resultSet = database.select(
        'SELECT SUM(sats) as total FROM zap_sats_earnings',
      );
      if (resultSet.isEmpty) return 0;
      final total = resultSet.first['total'];
      return total != null ? (total as num).toInt() : 0;
    } catch (e) {
      _log.warning('Failed to get total sats', e);
      return 0;
    }
  }

  Stream<int> watchTotalSats() {
    late StreamController<int> controller;

    Future<void> emit() async {
      try {
        final total = await getTotalSats();
        if (!controller.isClosed) {
          controller.add(total);
        }
      } catch (e) {
        _log.warning('Failed to load total sats', e);
      }
    }

    controller = StreamController<int>.broadcast(
      onListen: emit,
    );

    final sub = _changeController.stream.listen((_) => emit());

    controller.onCancel = () {
      sub.cancel();
      controller.close();
    };

    return controller.stream;
  }

  Future<int> getSatsForActivity(String activityId) async {
    try {
      final database = await _db.open();
      final resultSet = database.select(
        'SELECT SUM(sats) as total FROM zap_sats_earnings WHERE activity_id = ?',
        [activityId],
      );
      if (resultSet.isEmpty) return 0;
      final total = resultSet.first['total'];
      return total != null ? (total as num).toInt() : 0;
    } catch (e) {
      _log.warning('Failed to get sats for activity $activityId', e);
      return 0;
    }
  }

  Stream<int> watchSatsForActivity(String activityId) {
    late StreamController<int> controller;

    Future<void> emit() async {
      try {
        final total = await getSatsForActivity(activityId);
        if (!controller.isClosed) {
          controller.add(total);
        }
      } catch (e) {
        _log.warning('Failed to load sats for activity $activityId', e);
      }
    }

    controller = StreamController<int>.broadcast(
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
