import 'dart:async';
import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:ndk/ndk.dart';

import 'package:zapbook/core/config/zapbook_config.dart';
import 'package:zapbook/core/data/database/dao/circle_progress_dao.dart';
import 'package:zapbook/core/data/database/dao/reading_stats_dao.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/data/database/dao/zap_sats_earnings_dao.dart';
import 'package:zapbook/core/data/infrastructure/zap_earnings_service.dart';

@lazySingleton
class ReadingStatsService {
  ReadingStatsService(
    this._progressDao,
    this._statsDao,
    this._earningsDao,
    this._identity,
    this._earnings,
    this._ndk,
  );

  final CircleProgressDao _progressDao;
  final ReadingStatsDao _statsDao;
  final ZapSatsEarningsDao _earningsDao;
  final IdentityLocalDataSource _identity;
  final ZapEarningsService _earnings;
  final Ndk _ndk;

  final _log = logging.Logger('ReadingStatsService');

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    unawaited(_earnings.start());
  }

  Future<int> getTotalSatsEarned() async {
    final npub = await _identity.readNpub();
    if (npub == null) return 0;
    return _earningsDao.getTotalSats(npub);
  }

  Stream<ReadingStatsRecord?> watchStats() async* {
    final npub = await _identity.readNpub();
    if (npub == null || npub.isEmpty) {
      yield null;
      return;
    }
    yield* _statsDao.watchStats(npub);
  }

  Future<ReadingStatsRecord?> getStats(String? requestedNpub) async {
    final localNpub = await _identity.readNpub();
    final targetNpub = requestedNpub ?? localNpub;
    if (targetNpub == null || targetNpub.isEmpty) return null;

    if (targetNpub == localNpub) {
      return _statsDao.getStats(targetNpub);
    }

    try {
      final hex = targetNpub.startsWith('npub')
          ? Nip19.decode(targetNpub)
          : targetNpub;
      final response = _ndk.requests.query(
        filter: Filter(
          kinds: const [30000],
          authors: [hex],
          tags: const {
            '#d': ['zapbook_reading_stats'],
          },
        ),
      );

      final events = await response.future;
      final event = events.firstOrNull;
      if (event != null && event.content.isNotEmpty) {
        try {
          final payload = jsonDecode(event.content);
          return ReadingStatsRecord(
            pubKey: targetNpub,
            streak: payload['streak'] as int? ?? 0,
            lastActivityDate: payload['lastActivityDate'] as String? ?? '',
            booksRead: payload['booksRead'] as int? ?? 0,
            updatedAt: event.createdAt,
          );
        } catch (e, st) {
          _log.warning('Failed to decode event getStats ', e, st);
        }
      }
    } catch (e, st) {
      _log.warning('Failed to fetch public stats', e, st);
    }

    return null;
  }

  Future<int> getMilestones() async {
    final npub = await _identity.readNpub();
    if (npub == null || npub.isEmpty) return 0;
    return _progressDao.sumMilestonesReached(npub);
  }

  Future<void> recordProgressMade() async {
    final npub = await _identity.readNpub();
    if (npub == null || npub.isEmpty) return;

    final today = _today();
    final yesterday = _dayOffset(-1);

    final currentStats = await _statsDao.getStats(npub);

    int newStreak = currentStats?.streak ?? 0;
    final lastActivity = currentStats?.lastActivityDate;

    bool streakUpdated = false;

    if (lastActivity != today) {
      if (lastActivity == yesterday) {
        newStreak += 1;
      } else {
        newStreak = 1;
      }
      streakUpdated = true;
    }

    final newBooksRead = await _progressDao.countCompletedBooks(npub);

    if (!streakUpdated && newBooksRead == (currentStats?.booksRead ?? 0)) {
      return;
    }

    final record = ReadingStatsRecord(
      pubKey: npub,
      streak: newStreak,
      lastActivityDate: today,
      booksRead: newBooksRead,
      updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    await _statsDao.upsertStats(record);
    await _broadcastStats(record);
  }

  Future<void> _broadcastStats(ReadingStatsRecord record) async {
    try {
      final account = _ndk.accounts.getLoggedAccount();
      if (account == null || !account.signer.canSign()) return;

      final payload = {
        'streak': record.streak,
        'lastActivityDate': record.lastActivityDate,
        'booksRead': record.booksRead,
      };

      final event = Nip01Event(
        pubKey: account.pubkey,
        kind: 30000,
        tags: const [
          ['d', 'zapbook_reading_stats'],
        ],
        content: jsonEncode(payload),
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );

      final signed = await account.signer.sign(event);
      _ndk.broadcast.broadcast(
        nostrEvent: signed,
        specificRelays: ZapbookConfig.broadcastRelays,
      );
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
