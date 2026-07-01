import 'dart:async';
import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:marmot_dart/marmot_dart.dart';
import 'package:ndk/ndk.dart';
import 'package:zapbook/core/config/zapbook_config.dart';

import 'package:zapbook/core/domain/book_group_naming.dart';
import 'package:zapbook/core/services/decoded_message_cache.dart';
import 'package:zapbook/core/domain/milestone_payload.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';

@lazySingleton
class MilestoneService {
  MilestoneService(this._marmot, this._ndk, this._identity, this._cache) {
    unawaited(
      _identity.readNpub().then((npub) {
        if (npub != null && npub.isNotEmpty) _selfNpub = npub;
      }),
    );
  }

  final Marmot _marmot;
  final Ndk _ndk;
  final IdentityLocalDataSource _identity;
  final DecodedMessageCache _cache;

  static const _relays = ZapbookConfig.broadcastRelays;
  final _log = logging.Logger('MilestoneService');

  final Map<String, String> _groupIdBycircleBookId = {};
  final Map<String, String> _groupIdByName = {};
  bool _groupsCached = false;

  final Map<String, List<MilestonePayload>> _milestonesByBook = {};
  final Map<String, BookProgress> _selfByBook = {};
  final Map<String, Map<String, BookProgress>> _membersByBook = {};
  final Map<String, BookProgress> _lastPublished = {};
  final Map<String, MilestoneEvent> _events = {};
  final Map<String, Timer> _publishDebouncers = {};
  bool _isSyncing = false;

  final _tick = StreamController<String>.broadcast();
  String? _selfNpub;

  Stream<BookProgress> watchProgress(String circleBookId) => _tick.stream
      .where((id) => id == circleBookId)
      .map((_) => _selfByBook[circleBookId])
      .where((p) => p != null)
      .cast<BookProgress>();

  BookProgress? progressOf(String circleBookId) => _selfByBook[circleBookId];

  Stream<Map<String, BookProgress>> watchMembers(String circleBookId) => _tick
      .stream
      .where((id) => id == circleBookId)
      .map((_) => membersOf(circleBookId));

  Map<String, BookProgress> membersOf(String circleBookId) {
    final merged = Map<String, BookProgress>.from(
      _membersByBook[circleBookId] ?? {},
    );
    final self = _selfByBook[circleBookId];
    final me = _selfNpub;
    if (self != null && me != null) merged[me] = self;
    return merged;
  }

  Future<Map<String, BookProgress>> loadMembers(String circleBookId) async {
    final groupId = await _resolveGroupId(circleBookId);
    if (groupId != null) {
      try {
        final messages = await _marmot.getMessages(groupId);
        for (final message in messages) {
          ingestMessage(message);
        }
      } on Object catch (error, stack) {
        _log.warning('Load members failed', error, stack);
      }
    }
    return membersOf(circleBookId);
  }

  void ingestMessage(MarmotMessage message) {
    if (!(message.payloadJson ?? '').contains('zapbook.book.')) return;

    final payload = _cache.get(message);
    if (payload == null) return;

    final circleBookId =
        (payload['circleBookId'] ?? payload['book_id']) as String?;
    if (circleBookId == null) return;

    final type = payload['type'];
    final isMilestone = type == 'zapbook.book.milestone';
    final isCompleted = type == 'zapbook.book.completed';

    if (isMilestone || isCompleted) {
      _storeMilestoneEvent(message, circleBookId, type, payload, isCompleted);
    }

    final progress = _progressFromPayload(
      payload,
      circleBookId,
      message.senderNpub,
    );
    if (progress != null) {
      _storeProgress(circleBookId, message.senderNpub, progress);
    }
  }

  void _storeMilestoneEvent(
    MarmotMessage message,
    String circleBookId,
    dynamic type,
    Map<String, dynamic> payload,
    bool isCompleted,
  ) {
    final milestoneIdx = (payload['milestone_idx'] as num?)?.toInt() ?? 0;
    final currentPage = (payload['current_page'] as num?)?.toInt() ?? 0;
    final progressPct = (payload['progress_pct'] as num?)?.toDouble() ?? 0;

    _events[message.id] = MilestoneEvent(
      id: message.id,
      groupId: message.groupId,
      circleBookId: circleBookId,
      npub: message.senderNpub,
      milestoneIdx: milestoneIdx,
      currentPage: currentPage,
      progressPct: progressPct,
      completed: isCompleted,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        message.timestampSecs.toInt() * 1000,
      ),
    );

    if (type == 'zapbook.book.milestone') {
      _storeLocalMilestonePayload(
        circleBookId: circleBookId,
        milestoneIdx: milestoneIdx,
        currentWordCount: (payload['current_word_count'] as num?)?.toInt() ?? 0,
        totalWordCount: (payload['total_word_count'] as num?)?.toInt() ?? 0,
        progressPct: progressPct,
        currentPage: currentPage,
        quizOutlook: payload['quiz_outlook'] as String? ?? 'unavailable',
        reachedAt:
            payload['reachedAt'] as String? ??
            payload['reached_at'] as String? ??
            DateTime.fromMillisecondsSinceEpoch(
              message.timestampSecs.toInt() * 1000,
            ).toIso8601String(),
        sessionReadingSeconds:
            (payload['session_reading_seconds'] as num?)?.toInt() ?? 0,
      );
    }
  }

  void _storeLocalMilestonePayload({
    required String circleBookId,
    required int milestoneIdx,
    required int currentWordCount,
    required int totalWordCount,
    required double progressPct,
    required int currentPage,
    required String quizOutlook,
    required String reachedAt,
    required int sessionReadingSeconds,
  }) {
    final payload = MilestonePayload(
      circleBookId: circleBookId,
      milestoneIdx: milestoneIdx,
      currentWordCount: currentWordCount,
      totalWordCount: totalWordCount,
      progressPct: progressPct,
      currentPage: currentPage,
      sessionReadingSeconds: sessionReadingSeconds,
      quizOutlook: quizOutlook,
      reachedAt: reachedAt,
    );
    final list = _milestonesByBook.putIfAbsent(circleBookId, () => []);
    if (!list.any((m) => m.milestoneIdx == milestoneIdx)) {
      list.add(payload);
    }
  }

  void _storeProgress(String circleBookId, String npub, BookProgress progress) {
    final members = _membersByBook.putIfAbsent(circleBookId, () => {});
    final existing = members[npub];
    if (existing != null) {
      if (progress.updatedAtMs > 0 && existing.updatedAtMs > 0) {
        if (progress.updatedAtMs < existing.updatedAtMs) return;
      } else {
        if (progress.fraction < existing.fraction) return;
      }
    }
    members[npub] = progress;
    _tick.add(circleBookId);
  }

  BookProgress? _progressFromPayload(
    Map<String, dynamic> payload,
    String circleBookId,
    String npub,
  ) {
    final type = payload['type'];
    if (type == 'zapbook.book.progress') {
      final words = (payload['currentWordCount'] as num?)?.toInt() ?? 0;
      final total = (payload['totalWordCount'] as num?)?.toInt() ?? 0;
      return BookProgress(
        fraction: _readFraction(payload['fraction'], words, total),
        currentPage: (payload['currentPage'] as num?)?.toInt() ?? 0,
        currentWordCount: words,
        totalWordCount: total,
        updatedAtMs: (payload['lastReadAtMs'] as num?)?.toInt() ?? 0,
      );
    }

    if (type == 'zapbook.book.milestone') {
      final words = (payload['current_word_count'] as num?)?.toInt() ?? 0;
      final total = (payload['total_word_count'] as num?)?.toInt() ?? 0;
      final pct = (payload['progress_pct'] as num?)?.toDouble();
      return BookProgress(
        fraction: pct != null
            ? (pct / 100).clamp(0.0, 1.0)
            : _readFraction(null, words, total),
        currentPage: (payload['current_page'] as num?)?.toInt() ?? 0,
        currentWordCount: words,
        totalWordCount: total,
      );
    }

    if (type == 'zapbook.book.completed') {
      final prev = _membersByBook[circleBookId]?[npub];
      return BookProgress(
        fraction: 1,
        currentPage: prev?.currentPage ?? 0,
        currentWordCount: prev?.currentWordCount ?? 0,
        totalWordCount: prev?.totalWordCount ?? 0,
      );
    }

    return null;
  }

  double _readFraction(Object? raw, int words, int total) {
    final explicit = (raw as num?)?.toDouble();
    if (explicit != null) return explicit.clamp(0.0, 1.0);
    return total > 0 ? (words / total).clamp(0.0, 1.0) : 0;
  }

  List<MilestonePayload> getMilestones(String circleBookId) {
    final list = _milestonesByBook[circleBookId] ?? [];
    list.sort((a, b) => a.milestoneIdx.compareTo(b.milestoneIdx));
    return List.unmodifiable(list);
  }

  int get allMilestonesCount => _events.length;

  int get myMilestonesCount =>
      _events.values.where((e) => e.npub == _selfNpub && !e.completed).length;

  List<MilestoneEvent> milestoneEvents() {
    final list = _events.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return List.unmodifiable(list);
  }

  List<MilestoneEvent> eventsForGroup(String groupId) =>
      _events.values.where((e) => e.groupId == groupId).toList();

  Future<void> syncAll() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      _selfNpub ??= await _identity.readNpub();
      await _primeGroupCache();

      final groups = await _marmot.listGroups();
      for (final group in groups) {
        if (!BookGroupNaming.matches(group.name)) continue;
        final messages = await _marmot.getMessages(group.id);
        for (final message in messages) {
          ingestMessage(message);
        }
      }
    } on Object catch (error, stack) {
      _log.warning('Sync all failed', error, stack);
    } finally {
      _isSyncing = false;
    }
  }

  int get completedBooksCount {
    final me = _selfNpub;
    final done = <String>{};
    for (final circleBookId in {..._selfByBook.keys, ..._membersByBook.keys}) {
      final mine = membersOf(circleBookId)[me];
      if (mine != null && mine.fraction >= 1) done.add(circleBookId);
    }
    return done.length;
  }

  Set<String> get allMilestoneDates {
    final me = _selfNpub;
    return _events.values
        .where((e) => e.npub == me)
        .map((e) => e.timestamp.toUtc().toIso8601String().substring(0, 10))
        .toSet();
  }

  void recordBookCompleted(String circleBookId) {
    _storeProgress(
      circleBookId,
      _selfNpub ?? '',
      const BookProgress(
        fraction: 1,
        currentPage: 0,
        currentWordCount: 0,
        totalWordCount: 0,
      ),
    );
  }

  Future<void> publishBookCompleted(String circleBookId) async {
    final groupId = await _resolveGroupId(circleBookId);
    if (groupId == null) return;
    final npub = await _identity.readNpub();
    if (npub == null || npub.isEmpty) return;

    final payload = {
      'type': 'zapbook.book.completed',
      'book_id': circleBookId,
      'reached_at': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      final event = await _marmot.sendStructured(npub, groupId, payload);
      _publish(event);
      recordBookCompleted(circleBookId);
    } on Object catch (error, stack) {
      _log.warning('Publish book completed failed', error, stack);
    }
  }

  void updateProgress({
    required String circleBookId,
    required int currentPage,
    required int currentWordCount,
    required int totalWords,
    required double fraction,
  }) {
    final progress = BookProgress(
      fraction: fraction.clamp(0.0, 1.0),
      currentPage: currentPage,
      currentWordCount: currentWordCount,
      totalWordCount: totalWords,
    );
    _selfByBook[circleBookId] = progress;
    _tick.add(circleBookId);

    _publishDebouncers[circleBookId]?.cancel();
    _publishDebouncers[circleBookId] = Timer(const Duration(seconds: 5), () {
      final last = _lastPublished[circleBookId];
      if (last != null &&
          last.currentPage == currentPage &&
          last.currentWordCount == currentWordCount) {
        return;
      }
      _lastPublished[circleBookId] = progress;
      unawaited(_publishProgress(circleBookId));
    });
  }

  void flushProgress(String circleBookId) {
    final debouncer = _publishDebouncers[circleBookId];
    if (debouncer != null && debouncer.isActive) {
      debouncer.cancel();
      final progress = _selfByBook[circleBookId];
      if (progress != null) {
        final last = _lastPublished[circleBookId];
        if (last != null &&
            last.currentPage == progress.currentPage &&
            last.currentWordCount == progress.currentWordCount) {
          return;
        }
        _lastPublished[circleBookId] = progress;
        unawaited(_publishProgress(circleBookId));
      }
    }
  }

  Future<void> markCompleted(String circleBookId, {int? totalWords}) async {
    _publishDebouncers[circleBookId]?.cancel();
    final current = _selfByBook[circleBookId];
    final total = totalWords ?? current?.totalWordCount ?? 0;
    final completed = BookProgress(
      fraction: 1,
      currentPage: current?.currentPage ?? 0,
      currentWordCount: total,
      totalWordCount: total,
    );
    _selfByBook[circleBookId] = completed;
    _lastPublished[circleBookId] = completed;
    _tick.add(circleBookId);
    await _publishProgress(circleBookId);
  }

  Future<void> _publishProgress(String circleBookId) async {
    final groupId = await _resolveGroupId(circleBookId);
    if (groupId == null) return;
    final npub = await _identity.readNpub();
    if (npub == null || npub.isEmpty) return;
    _selfNpub ??= npub;
    final progress = _selfByBook[circleBookId];
    if (progress == null) return;

    final payload = {
      'type': 'zapbook.book.progress',
      'circleBookId': circleBookId,
      'lastReadAtMs': DateTime.now().millisecondsSinceEpoch,
      'fraction': progress.fraction,
      'currentPage': progress.currentPage,
      'currentWordCount': progress.currentWordCount,
      'totalWordCount': progress.totalWordCount,
    };

    try {
      final event = await _marmot.sendStructured(npub, groupId, payload);
      _publish(event);
    } on Object catch (error, stack) {
      _log.warning('Publish progress failed', error, stack);
    }
  }

  Future<void> publishMilestone({
    required String circleBookId,
    required int milestoneIdx,
    required int currentWordCount,
    required int totalWordCount,
    required double progressPct,
    required int currentPage,
    required int sessionEngagedMs,
    String quizOutlook = 'unavailable',
  }) async {
    final groupId = await _resolveGroupId(circleBookId);
    if (groupId == null) return;

    final npub = await _identity.readNpub();
    if (npub == null || npub.isEmpty) return;

    final payload = MilestonePayload(
      circleBookId: circleBookId,
      milestoneIdx: milestoneIdx,
      currentWordCount: currentWordCount,
      totalWordCount: totalWordCount,
      progressPct: progressPct,
      currentPage: currentPage,
      sessionReadingSeconds: sessionEngagedMs ~/ 1000,
      quizOutlook: quizOutlook,
      reachedAt: DateTime.now().toUtc().toIso8601String(),
    );

    _storeLocalMilestonePayload(
      circleBookId: payload.circleBookId,
      milestoneIdx: payload.milestoneIdx,
      currentWordCount: payload.currentWordCount,
      totalWordCount: payload.totalWordCount,
      progressPct: payload.progressPct,
      currentPage: payload.currentPage,
      quizOutlook: payload.quizOutlook,
      reachedAt: payload.reachedAt,
      sessionReadingSeconds: payload.sessionReadingSeconds,
    );

    _publishDebouncers[circleBookId]?.cancel();
    _lastPublished[circleBookId] = BookProgress(
      fraction: (progressPct / 100).clamp(0.0, 1.0),
      currentPage: currentPage,
      currentWordCount: currentWordCount,
      totalWordCount: totalWordCount,
    );

    try {
      final event = await _marmot.sendStructured(
        npub,
        groupId,
        payload.toJson(),
      );
      _publish(event);
    } on Object catch (error, stack) {
      _log.warning('Publish milestone failed', error, stack);
    }
  }

  Future<void> _primeGroupCache() async {
    if (_groupsCached) return;
    try {
      final groups = await _marmot.listGroups();
      for (final group in groups) {
        _groupIdByName[group.name] = group.id;
      }
      _groupsCached = true;
    } on Object catch (error, trace) {
      _log.warning('_primeGroupCache', error, trace);
    }
  }

  Future<String?> _resolveGroupId(String circleBookId) async {
    final cached = _groupIdBycircleBookId[circleBookId];
    if (cached != null) return cached;

    await _primeGroupCache();
    final name = BookGroupNaming.legacyNameFor(circleBookId);

    final id = _groupIdByName[name];
    if (id != null) {
      _groupIdBycircleBookId[circleBookId] = id;
      return id;
    }

    final groups = await _marmot.listGroups();
    for (final group in groups) {
      if (group.name == name) {
        _groupIdBycircleBookId[circleBookId] = group.id;
        _groupIdByName[name] = group.id;
        return group.id;
      }
    }
    return null;
  }

  void _publish(String eventJson) {
    try {
      final map = jsonDecode(eventJson) as Map<String, dynamic>;
      final tags = (map['tags'] as List)
          .map((tag) => (tag as List).map((e) => e.toString()).toList())
          .toList();
      String pubKey = map['pubkey'] as String;
      if (pubKey.startsWith('npub')) {
        pubKey = Nip19.decode(pubKey);
      }
      final nipEvent = Nip01Event(
        id: map['id'] as String?,
        pubKey: pubKey,
        kind: (map['kind'] as num).toInt(),
        tags: tags,
        content: map['content'] as String,
        sig: map['sig'] as String?,
        createdAt: (map['created_at'] as num).toInt(),
      );
      _ndk.broadcast.broadcast(nostrEvent: nipEvent, specificRelays: _relays);
    } on Object catch (error, stack) {
      _log.warning('Relay publish failed', error, stack);
    }
  }
}

class MilestoneEvent {
  const MilestoneEvent({
    required this.id,
    required this.groupId,
    required this.circleBookId,
    required this.npub,
    required this.milestoneIdx,
    required this.currentPage,
    required this.progressPct,
    required this.completed,
    required this.timestamp,
  });

  final String id;
  final String groupId;
  final String circleBookId;
  final String npub;
  final int milestoneIdx;
  final int currentPage;
  final double progressPct;
  final bool completed;
  final DateTime timestamp;
}

class BookProgress {
  const BookProgress({
    required this.fraction,
    required this.currentPage,
    required this.currentWordCount,
    required this.totalWordCount,
    this.updatedAtMs = 0,
  });

  final double fraction;
  final int currentPage;
  final int currentWordCount;
  final int totalWordCount;
  final int updatedAtMs;
}
