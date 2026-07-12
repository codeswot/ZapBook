import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:marmot_dart/marmot_dart.dart';

import 'package:zapbook/core/data/dao/circle_progress_dao.dart';
import 'package:zapbook/core/data/dao/reading_stats_dao.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/models/app_message.dart';
import 'package:zapbook/core/services/group_envelope_service.dart';
import 'package:zapbook/core/services/zap_earnings_service.dart';

@lazySingleton
class ReadingStatsService {
  ReadingStatsService(
    this._progressDao,
    this._statsDao,
    this._identity,
    this._earnings,
    this._marmot,
    this._envelope,
  );

  final CircleProgressDao _progressDao;
  final ReadingStatsDao _statsDao;
  final IdentityLocalDataSource _identity;
  final ZapEarningsService _earnings;
  final Marmot _marmot;
  final GroupEnvelopeService _envelope;

  final _log = logging.Logger('ReadingStatsService');

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    unawaited(_earnings.start());
  }

  Stream<ReadingStatsRecord?> watchStats() async* {
    final npub = await _identity.readNpub();
    if (npub == null || npub.isEmpty) {
      yield null;
      return;
    }
    yield* _statsDao.watchStats(npub);
  }

  Future<ReadingStatsRecord?> getStats() async {
    final npub = await _identity.readNpub();
    if (npub == null || npub.isEmpty) return null;
    return _statsDao.getStats(npub);
  }

  Future<int> getMilestones() async {
    final npub = await _identity.readNpub();
    if (npub == null || npub.isEmpty) return 0;
    return _progressDao.sumMilestonesReached(npub);
  }

  Future<void> recordProgressMade(String groupId) async {
    final npub = await _identity.readNpub();
    if (npub == null || npub.isEmpty) return;

    final today = _today();
    final yesterday = _dayOffset(-1);

    final currentStats = await _statsDao.getStats(npub);

    int newStreak = currentStats?.streak ?? 0;
    final lastActivity = currentStats?.lastActivityDate;

    if (lastActivity == today) {
      return;
    }

    if (lastActivity == yesterday) {
      newStreak += 1;
    } else {
      newStreak = 1;
    }

    final record = ReadingStatsRecord(
      pubKey: npub,
      streak: newStreak,
      lastActivityDate: today,
      booksRead: await _progressDao.countCompletedBooks(npub),
      satsEarned: _earnings.totalEarned.value,
      updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    await _statsDao.upsertStats(record);

    await _broadcastStats(groupId, record);
  }

  Future<void> _broadcastStats(
    String groupId,
    ReadingStatsRecord record,
  ) async {
    try {
      final payload = {
        'type': AppMessageTypes.readingStats,
        'streak': record.streak,
        'lastActivityDate': record.lastActivityDate,
        'booksRead': record.booksRead,
        'satsEarned': record.satsEarned,
      };

      final event = await _marmot.sendStructured(
        record.pubKey,
        groupId,
        payload,
      );
      await _envelope.publish(event);
    } on Object catch (error, stack) {
      _log.warning('Publish stats failed', error, stack);
    }
  }

  String _today() => DateTime.now().toUtc().toIso8601String().substring(0, 10);

  String _dayOffset(int offset) {
    final d = DateTime.now().toUtc().add(Duration(days: offset));
    return d.toIso8601String().substring(0, 10);
  }
}
