import 'dart:async';
import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:marmot_dart/marmot_dart.dart';
import 'package:ndk/ndk.dart';

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

  static const _groupPrefix = 'zapbook-book-';
  static const _relays = NostrService.broadcastRelays;

  final _log = logging.Logger('MilestoneService');
  final Map<String, String> _groupIdByBookId = {};
  final Map<String, List<MilestonePayload>> _milestonesByBook = {};
  final Map<String, BookProgress> _selfByBook = {};
  final Map<String, Map<String, BookProgress>> _membersByBook = {};
  final Map<String, BookProgress> _lastPublished = {};
  final _completedBooks = <String>{};
  final Map<String, MilestoneEvent> _events = {};
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
    final payload = _decode(message.payloadJson);
    if (payload == null) return;
    final bookId = (payload['bookId'] ?? payload['book_id']) as String?;
    if (bookId == null) return;

    final type = payload['type'];
    if (type == 'zapbook.book.milestone' || type == 'zapbook.book.completed') {
      _events[message.id] = MilestoneEvent(
        id: message.id,
        groupId: message.groupId,
        bookId: bookId,
        npub: message.senderNpub,
        milestoneIdx: (payload['milestone_idx'] as num?)?.toInt() ?? 0,
        currentPage: (payload['current_page'] as num?)?.toInt() ?? 0,
        progressPct: (payload['progress_pct'] as num?)?.toDouble() ?? 0,
        completed: type == 'zapbook.book.completed',
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          message.timestampSecs.toInt() * 1000,
        ),
      );
    }

    final progress = _progressFromPayload(payload, bookId, message.senderNpub);
    if (progress == null) return;

    final members = _membersByBook.putIfAbsent(bookId, () => {});
    final existing = members[message.senderNpub];
    if (existing != null && progress.fraction < existing.fraction) return;
    members[message.senderNpub] = progress;
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
    switch (payload['type']) {
      case 'zapbook.book.progress':
        final words = (payload['currentWordCount'] as num?)?.toInt() ?? 0;
        final total = (payload['totalWordCount'] as num?)?.toInt() ?? 0;
        return BookProgress(
          fraction: _readFraction(payload['fraction'], words, total),
          currentPage: (payload['currentPage'] as num?)?.toInt() ?? 0,
          currentWordCount: words,
          totalWordCount: total,
        );
      case 'zapbook.book.milestone':
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
      case 'zapbook.book.completed':
        final prev = _membersByBook[bookId]?[npub];
        return BookProgress(
          fraction: 1,
          currentPage: prev?.currentPage ?? 0,
          currentWordCount: prev?.currentWordCount ?? 0,
          totalWordCount: prev?.totalWordCount ?? 0,
        );
      default:
        return null;
    }
  }

  double _readFraction(Object? raw, int words, int total) {
    final explicit = (raw as num?)?.toDouble();
    if (explicit != null) return explicit.clamp(0.0, 1.0);
    return total > 0 ? (words / total).clamp(0.0, 1.0) : 0;
  }

  List<MilestonePayload> getMilestones(String bookId) =>
      List.unmodifiable(_milestonesByBook[bookId] ?? []);

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
    try {
      _selfNpub ??= await _identity.readNpub();
      final groups = await _marmot.listGroups();
      for (final group in groups) {
        if (!group.name.startsWith(_groupPrefix)) continue;
        final messages = await _marmot.getMessages(group.id);
        for (final message in messages) {
          ingestMessage(message);
        }
      }
    } on Object catch (error, stack) {
      _log.warning('Sync all failed', error, stack);
    }
  }

  int get completedBooksCount {
    final me = _selfNpub;
    final done = <String>{..._completedBooks};
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
    _completedBooks.add(bookId);
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

    final last = _lastPublished[bookId];
    if (last != null &&
        last.currentPage == currentPage &&
        last.currentWordCount == currentWordCount) {
      return;
    }
    _lastPublished[bookId] = progress;
    unawaited(_publishProgress(bookId));
  }

  Future<void> markCompleted(String bookId, {int? totalWords}) async {
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

    _storeLocal(payload);
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

  void _storeLocal(MilestonePayload payload) {
    final list = _milestonesByBook.putIfAbsent(payload.bookId, () => []);
    final exists = list.any((m) => m.milestoneIdx == payload.milestoneIdx);
    if (!exists) list.add(payload);
  }

  Future<String?> _resolveGroupId(String bookId) async {
    final cached = _groupIdByBookId[bookId];
    if (cached != null) return cached;
    final name = '$_groupPrefix$bookId';
    final groups = await _marmot.listGroups();
    for (final group in groups) {
      if (group.name == name) {
        _groupIdByBookId[bookId] = group.id;
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
      final nipEvent = Nip01Event(
        id: map['id'] as String?,
        pubKey: map['pubkey'] as String,
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
  });

  final double fraction;
  final int currentPage;
  final int currentWordCount;
  final int totalWordCount;
}
