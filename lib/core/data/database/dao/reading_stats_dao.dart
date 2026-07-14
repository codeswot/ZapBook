import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:zapbook/core/data/database/app_database.dart';

class ReadingStatsRecord {
  final String pubKey;
  final int streak;
  final String? lastActivityDate;
  final int booksRead;
  final int updatedAt;

  ReadingStatsRecord({
    required this.pubKey,
    required this.streak,
    this.lastActivityDate,
    required this.booksRead,
    required this.updatedAt,
  });

  int get effectiveStreak {
    if (lastActivityDate == null) return 0;
    final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    final yesterday = DateTime.now()
        .toUtc()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);

    if (lastActivityDate == today || lastActivityDate == yesterday) {
      return streak;
    }
    return 0;
  }

  factory ReadingStatsRecord.fromRow(Map<String, dynamic> row) {
    return ReadingStatsRecord(
      pubKey: row['pub_key'] as String,
      streak: (row['streak'] as num).toInt(),
      lastActivityDate: row['last_activity_date'] as String?,
      booksRead: (row['books_read'] as num).toInt(),
      updatedAt: (row['updated_at'] as num).toInt(),
    );
  }
}

@lazySingleton
class ReadingStatsDao {
  final AppDatabase _db;
  final _changeController = StreamController<void>.broadcast();
  final _log = logging.Logger('ReadingStatsDao');

  ReadingStatsDao(this._db);

  Future<void> upsertStats(ReadingStatsRecord? stats) async {
    if (stats == null) return;
    try {
      final database = await _db.open();
      final stmt = database.prepare('''
        INSERT INTO reading_stats (
          pub_key, streak, last_activity_date, books_read, updated_at
        ) VALUES (?, ?, ?, ?, ?)
        ON CONFLICT(pub_key) DO UPDATE SET
          streak = excluded.streak,
          last_activity_date = excluded.last_activity_date,
          books_read = excluded.books_read,
          updated_at = excluded.updated_at
        WHERE excluded.updated_at > reading_stats.updated_at
      ''');

      stmt.execute([
        stats.pubKey,
        stats.streak,
        stats.lastActivityDate,
        stats.booksRead,
        stats.updatedAt,
      ]);

      stmt.close();
      _changeController.add(null);
    } on Object catch (error, stack) {
      _log.warning('Failed to upsert reading stats', error, stack);
    }
  }

  Future<ReadingStatsRecord?> getStats(String pubKey) async {
    try {
      final database = await _db.open();
      final resultSet = database.select(
        'SELECT * FROM reading_stats WHERE pub_key = ?',
        [pubKey],
      );
      if (resultSet.isEmpty) return null;
      return ReadingStatsRecord.fromRow(resultSet.first);
    } catch (e) {
      _log.warning('Failed to get reading stats for $pubKey', e);
      return null;
    }
  }

  Stream<ReadingStatsRecord?> watchStats(String pubKey) {
    late StreamController<ReadingStatsRecord?> controller;

    Future<void> emit() async {
      try {
        final stats = await getStats(pubKey);
        if (!controller.isClosed) {
          controller.add(stats);
        }
      } catch (e) {
        _log.warning('Failed to load stats for $pubKey', e);
      }
    }

    controller = StreamController<ReadingStatsRecord?>.broadcast(
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
