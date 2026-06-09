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
  MilestoneService(this._marmot, this._ndk, this._identity);

  final Marmot _marmot;
  final Ndk _ndk;
  final IdentityLocalDataSource _identity;

  static const _groupPrefix = 'zapbook-book-';
  static const _relays = NostrService.broadcastRelays;

  final _log = logging.Logger('MilestoneService');
  final Map<String, String> _groupIdByBookId = {};
  final Map<String, List<MilestonePayload>> _milestonesByBook = {};
  final _completedBooks = <String>{};

  List<MilestonePayload> getMilestones(String bookId) =>
      List.unmodifiable(_milestonesByBook[bookId] ?? []);

  int get totalBooksCompleted => _completedBooks.length;

  Set<String> get allMilestoneDates {
    final dates = <String>{};
    for (final list in _milestonesByBook.values) {
      for (final m in list) {
        dates.add(m.reachedAt.substring(0, 10));
      }
    }
    return dates;
  }

  void recordBookCompleted(String bookId) {
    _completedBooks.add(bookId);
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
      _ndk.broadcast.broadcast(
        nostrEvent: nipEvent,
        specificRelays: _relays,
      );
    } on Object catch (error, stack) {
      _log.warning('Relay publish failed', error, stack);
    }
  }
}
