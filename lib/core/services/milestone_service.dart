import 'dart:async';
import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:marmot_dart/marmot_dart.dart';
import 'package:ndk/ndk.dart';

import 'package:zapbook/core/domain/book_group_naming.dart';
import 'package:zapbook/core/domain/milestone_payload.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/nostr_service.dart';

@lazySingleton
class MilestoneService {
  MilestoneService(this._marmot, this._ndk, this._identity) {
    unawaited(
      _identity.readNpub().then((npub) {
        if (npub != null && npub.isNotEmpty) _selfNpub = npub;
      }),
    );
  }

  final Marmot _marmot;
  final Ndk _ndk;
  final IdentityLocalDataSource _identity;

  static const _relays = NostrService.broadcastRelays;
  final _log = logging.Logger('MilestoneService');

  final Map<String, String> _groupIdByBookId = {};
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

  Stream<BookProgress> watchProgress(String bookId) => _tick.stream
      .where((id) => id == bookId)
      .map((_) => _selfByBook[bookId])
      .where((p) => p != null)
      .cast<BookProgress>();

  BookProgress? progressOf(String bookId) => _selfByBook[bookId];

  Stream<Map<String, BookProgress>> watchMembers(String bookId) =>
      _tick.stream.where((id) => id == bookId).map((_) => membersOf(bookId));

  Map<String, BookProgress> membersOf(String bookId) {
    final merged = Map<String, BookProgress>.from(_membersByBook[bookId] ?? {});
    final self = _selfByBook[bookId];
    final me = _selfNpub;
    if (self != null && me != null) merged[me] = self;
    return merged;
  }

  Future<Map<String, BookProgress>> loadMembers(String bookId) async {
    final groupId = await _resolveGroupId(bookId);
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
    return membersOf(bookId);
  }

  void ingestMessage(MarmotMessage message) {
    if (!(message.payloadJson ?? '').contains('zapbook.book.')) return;

    final payload = _decode(message.payloadJson);
    if (payload == null) return;

    final bookId = (payload['bookId'] ?? payload['book_id']) as String?;
    if (bookId == null) return;

    final type = payload['type'];
    final isMilestone = type == 'zapbook.book.milestone';
    final isCompleted = type == 'zapbook.book.completed';

    if (isMilestone || isCompleted) {
      _storeMilestoneEvent(message, bookId, type, payload, isCompleted);
    }

    final progress = _progressFromPayload(payload, bookId, message.senderNpub);
    if (progress != null) {
      _storeProgress(bookId, message.senderNpub, progress);
    }
  }

  void _storeMilestoneEvent(
    MarmotMessage message,
    String bookId,
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
      bookId: bookId,
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
        bookId: bookId,
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
    required String bookId,
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
      bookId: bookId,
      milestoneIdx: milestoneIdx,
      currentWordCount: currentWordCount,
      totalWordCount: totalWordCount,
      progressPct: progressPct,
      currentPage: currentPage,
      sessionReadingSeconds: sessionReadingSeconds,
      quizOutlook: quizOutlook,
      reachedAt: reachedAt,
    );
    final list = _milestonesByBook.putIfAbsent(bookId, () => []);
    if (!list.any((m) => m.milestoneIdx == milestoneIdx)) {
      list.add(payload);
    }
  }

  void _storeProgress(String bookId, String npub, BookProgress progress) {
    final members = _membersByBook.putIfAbsent(bookId, () => {});
    final existing = members[npub];
    if (existing != null) {
      if (progress.updatedAtMs > 0 && existing.updatedAtMs > 0) {
        if (progress.updatedAtMs < existing.updatedAtMs) return;
      } else {
        if (progress.fraction < existing.fraction) return;
      }
    }
    members[npub] = progress;
    _tick.add(bookId);
  }

  Map<String, dynamic>? _decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on Object {
      return null;
    }
  }

  BookProgress? _progressFromPayload(
    Map<String, dynamic> payload,
    String bookId,
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
      final prev = _membersByBook[bookId]?[npub];
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

  List<MilestonePayload> getMilestones(String bookId) {
    final list = _milestonesByBook[bookId] ?? [];
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
    for (final bookId in {..._selfByBook.keys, ..._membersByBook.keys}) {
      final mine = membersOf(bookId)[me];
      if (mine != null && mine.fraction >= 1) done.add(bookId);
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

  void recordBookCompleted(String bookId) {
    _storeProgress(
      bookId,
      _selfNpub ?? '',
      const BookProgress(
        fraction: 1,
        currentPage: 0,
        currentWordCount: 0,
        totalWordCount: 0,
      ),
    );
  }

  Future<void> publishBookCompleted(String bookId) async {
    final groupId = await _resolveGroupId(bookId);
    if (groupId == null) return;
    final npub = await _identity.readNpub();
    if (npub == null || npub.isEmpty) return;

    final payload = {
      'type': 'zapbook.book.completed',
      'book_id': bookId,
      'reached_at': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      final event = await _marmot.sendStructured(npub, groupId, payload);
      _publish(event);
      recordBookCompleted(bookId);
    } on Object catch (error, stack) {
      _log.warning('Publish book completed failed', error, stack);
    }
  }

  void updateProgress({
    required String bookId,
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
    _selfByBook[bookId] = progress;
    _tick.add(bookId);

    _publishDebouncers[bookId]?.cancel();
    _publishDebouncers[bookId] = Timer(const Duration(seconds: 5), () {
      final last = _lastPublished[bookId];
      if (last != null &&
          last.currentPage == currentPage &&
          last.currentWordCount == currentWordCount) {
        return;
      }
      _lastPublished[bookId] = progress;
      unawaited(_publishProgress(bookId));
    });
  }

  void flushProgress(String bookId) {
    final debouncer = _publishDebouncers[bookId];
    if (debouncer != null && debouncer.isActive) {
      debouncer.cancel();
      final progress = _selfByBook[bookId];
      if (progress != null) {
        final last = _lastPublished[bookId];
        if (last != null &&
            last.currentPage == progress.currentPage &&
            last.currentWordCount == progress.currentWordCount) {
          return;
        }
        _lastPublished[bookId] = progress;
        unawaited(_publishProgress(bookId));
      }
    }
  }

  Future<void> markCompleted(String bookId, {int? totalWords}) async {
    _publishDebouncers[bookId]?.cancel();
    final current = _selfByBook[bookId];
    final total = totalWords ?? current?.totalWordCount ?? 0;
    final completed = BookProgress(
      fraction: 1,
      currentPage: current?.currentPage ?? 0,
      currentWordCount: total,
      totalWordCount: total,
    );
    _selfByBook[bookId] = completed;
    _lastPublished[bookId] = completed;
    _tick.add(bookId);
    await _publishProgress(bookId);
  }

  Future<void> _publishProgress(String bookId) async {
    final groupId = await _resolveGroupId(bookId);
    if (groupId == null) return;
    final npub = await _identity.readNpub();
    if (npub == null || npub.isEmpty) return;
    _selfNpub ??= npub;
    final progress = _selfByBook[bookId];
    if (progress == null) return;

    final payload = {
      'type': 'zapbook.book.progress',
      'bookId': bookId,
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
    required String bookId,
    required int milestoneIdx,
    required int currentWordCount,
    required int totalWordCount,
    required double progressPct,
    required int currentPage,
    required int sessionEngagedMs,
    String quizOutlook = 'unavailable',
  }) async {
    final groupId = await _resolveGroupId(bookId);
    if (groupId == null) return;

    final npub = await _identity.readNpub();
    if (npub == null || npub.isEmpty) return;

    final payload = MilestonePayload(
      bookId: bookId,
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
      bookId: payload.bookId,
      milestoneIdx: payload.milestoneIdx,
      currentWordCount: payload.currentWordCount,
      totalWordCount: payload.totalWordCount,
      progressPct: payload.progressPct,
      currentPage: payload.currentPage,
      quizOutlook: payload.quizOutlook,
      reachedAt: payload.reachedAt,
      sessionReadingSeconds: payload.sessionReadingSeconds,
    );

    _publishDebouncers[bookId]?.cancel();
    _lastPublished[bookId] = BookProgress(
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

  Future<String?> _resolveGroupId(String bookId) async {
    final cached = _groupIdByBookId[bookId];
    if (cached != null) return cached;

    await _primeGroupCache();
    final name = BookGroupNaming.nameFor(bookId);

    final id = _groupIdByName[name];
    if (id != null) {
      _groupIdByBookId[bookId] = id;
      return id;
    }

    final groups = await _marmot.listGroups();
    for (final group in groups) {
      if (group.name == name) {
        _groupIdByBookId[bookId] = group.id;
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
    required this.bookId,
    required this.npub,
    required this.milestoneIdx,
    required this.currentPage,
    required this.progressPct,
    required this.completed,
    required this.timestamp,
  });

  final String id;
  final String groupId;
  final String bookId;
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
