import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:marmot_dart/marmot_dart.dart';

import 'package:uuid/uuid.dart';
import 'package:zapbook/core/data/database/dao/cheers_dao.dart';
import 'package:zapbook/core/data/database/dao/circle_progress_dao.dart';
import 'package:zapbook/core/domain/entities/milestone_book_session.dart';
import 'package:zapbook/core/domain/entities/cheers_activity_message.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/domain/entities/app_message.dart';
import 'package:zapbook/core/models/circle_member_progress.dart';
import 'package:zapbook/core/data/infrastructure/group_envelope_service.dart';
import 'package:zapbook/core/data/infrastructure/reading_stats_service.dart';

@lazySingleton
class MilestoneService {
  MilestoneService(
    this._marmot,
    this._identity,
    this._envelope,
    this._progressDao,
    this._cheersDao,
    this._stats,
  );

  final Marmot _marmot;
  final IdentityLocalDataSource _identity;
  final GroupEnvelopeService _envelope;
  final CircleProgressDao _progressDao;
  final CheersDao _cheersDao;
  final ReadingStatsService _stats;

  final _log = logging.Logger('MilestoneService');

  final Map<String, MilestoneBookSession> _sessions = {};
  Future<void> _serial = Future.value();
  String? _cachedNpub;

  void reportProgress({
    required String circleDirId,
    required String groupId,
    required int currentPage,
    required int currentWordCount,
    required int totalWords,
    required double fraction,
    int milestonesReached = 0,
    bool bookCompleted = false,
  }) {
    _serial = _serial
        .then(
          (_) => _report(
            circleDirId: circleDirId,
            groupId: groupId,
            currentPage: currentPage,
            currentWordCount: currentWordCount,
            totalWords: totalWords,
            fraction: bookCompleted ? 1.0 : fraction.clamp(0.0, 1.0),
            milestonesReached: milestonesReached,
            bookCompleted: bookCompleted,
          ),
        )
        .onError((error, stack) {
          _log.warning('Report progress failed', error, stack);
        });
  }

  void flushProgress(String circleDirId) {
    final session = _sessions[circleDirId];
    if (session == null) return;
    session.cancelDebounce();
    _dispatchPending(circleDirId, session);
  }

  void closeBook(String circleDirId) {
    _serial = _serial
        .then((_) {
          flushProgress(circleDirId);
          _sessions.remove(circleDirId);
        })
        .onError((error, stack) {
          _log.warning('Close book failed', error, stack);
        });
  }

  void _dispatchPending(String circleDirId, MilestoneBookSession session) {
    final report = session.pending;
    session.pending = null;
    if (report != null) unawaited(_send(circleDirId, session, report));
  }

  Future<void> _report({
    required String circleDirId,
    required String groupId,
    required int currentPage,
    required int currentWordCount,
    required int totalWords,
    required double fraction,
    required int milestonesReached,
    required bool bookCompleted,
  }) async {
    final session = _sessions.putIfAbsent(circleDirId, () {
      if (_sessions.length >= 10) {
        final oldestId = _sessions.keys.first;
        flushProgress(oldestId);
        _sessions.remove(oldestId);
      }
      return MilestoneBookSession();
    });
    final snapshot = (
      page: currentPage,
      words: currentWordCount,
      milestones: milestonesReached,
      completed: bookCompleted,
    );
    final last = session.lastSent;
    if (last == snapshot || session.pending?.snapshot == snapshot) return;

    _cachedNpub ??= await _identity.readNpub();
    final npub = _cachedNpub;
    if (npub == null || npub.isEmpty) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final previous = await _progressDao.getProgress(
      groupId: groupId,
      bookId: circleDirId,
      pubKey: npub,
    );
    final next = CircleMemberProgress(
      id: const Uuid().v4(),
      groupId: groupId,
      pubKey: npub,
      bookId: circleDirId,
      pageIndex: currentPage,
      progressPercentage: fraction,
      updatedAt: nowMs ~/ 1000,
      milestonesReached: milestonesReached,
      completed: bookCompleted,
    );

    await _progressDao.upsertProgress(next);

    final cheer = CheersActivityMessage.cheerFromProgress(
      id: const Uuid().v4(),
      actorNpub: npub,
      groupId: groupId,
      timestampSecs: next.updatedAt,
      previous: previous,
      next: next,
    );
    if (cheer != null) {
      await _cheersDao.saveActivity(npub, cheer);
    }

    if (_isForwardProgress(previous, next)) {
      await _stats.recordProgressMade();
    }

    final report = (
      localId: next.id,
      npub: npub,
      groupId: groupId,
      fraction: fraction,
      totalWords: totalWords,
      snapshot: snapshot,
      nowMs: nowMs,
    );
    final significant =
        milestonesReached > (last?.milestones ?? 0) ||
        (bookCompleted && !(last?.completed ?? false));

    session.cancelDebounce();
    if (significant) {
      session.pending = null;
      unawaited(_send(circleDirId, session, report));
      return;
    }

    session.pending = report;
    session.debounce = Timer(const Duration(seconds: 2), () {
      session.debounce = null;
      _dispatchPending(circleDirId, session);
    });
  }

  bool _isForwardProgress(
    CircleMemberProgress? previous,
    CircleMemberProgress next,
  ) {
    if (previous == null) {
      return next.progressPercentage > 0 ||
          next.pageIndex > 0 ||
          next.milestonesReached > 0 ||
          next.completed;
    }
    return next.progressPercentage > previous.progressPercentage ||
        next.pageIndex > previous.pageIndex ||
        next.milestonesReached > previous.milestonesReached ||
        (next.completed && !previous.completed);
  }

  Future<void> _send(
    String circleDirId,
    MilestoneBookSession session,
    MilestoneReport report,
  ) async {
    session.lastSent = report.snapshot;
    final payload = {
      'type': AppMessageTypes.bookProgress,
      'circleDirId': circleDirId,
      'lastReadAtMs': report.nowMs,
      'fraction': report.fraction,
      'currentPage': report.snapshot.page,
      'currentWordCount': report.snapshot.words,
      'totalWordCount': report.totalWords,
      'milestonesReached': report.snapshot.milestones,
      'bookCompleted': report.snapshot.completed,
    };

    try {
      final eventId = await _marmot.sendStructured(
        report.npub,
        report.groupId,
        payload,
      );

      await _progressDao.replaceId(report.localId, eventId);

      await _envelope.publish(eventId);
    } on Object catch (error, stack) {
      _log.warning('Publish progress failed', error, stack);
    }
  }
}
