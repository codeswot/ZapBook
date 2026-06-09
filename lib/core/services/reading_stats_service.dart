import 'dart:async';
import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart';

import 'package:zapbook/core/data/cache/nostr_cache_store.dart';
import 'package:zapbook/core/services/milestone_service.dart';
import 'package:zapbook/core/services/nostr_service.dart';

@lazySingleton
class ReadingStatsService {
  ReadingStatsService(this._ndk, this._cache, this._milestoneService);

  final Ndk _ndk;
  final NostrCacheStore _cache;
  final MilestoneService _milestoneService;

  static const _statsKind = 30078;
  static const _statsTag = 'zapbook:stats';

  int _satsEarned = 0;
  final _milestoneDates = <String>{};
  String? _lastPublishDate;
  bool _loaded = false;

  int get booksRead => _milestoneService.totalBooksCompleted;
  int get satsEarned => _satsEarned;

  int get streak {
    final dates = {..._milestoneService.allMilestoneDates, ..._milestoneDates};
    if (dates.isEmpty) return 0;
    final sorted = dates.toList()..sort();
    final today = _today();
    final yesterday = _dayOffset(-1);
    final lastDate = sorted.last;
    if (lastDate != today && lastDate != yesterday) return 0;
    var count = 0;
    var expected = lastDate;
    for (var i = sorted.length - 1; i >= 0; i--) {
      if (sorted[i] == expected) {
        count++;
        expected = _dayBefore(expected);
      } else {
        break;
      }
    }
    return count;
  }

  Future<void> load() async {
    if (_loaded) return;
    final pubkey = _ndk.accounts.getPublicKey();
    if (pubkey == null) return;

    final events = _cache.loadEvents(pubKeys: [pubkey], kinds: [_statsKind]);
    final match = events.where((e) {
      final dTag = e.tags.where((t) => t.length >= 2 && t[0] == 'd');
      return dTag.isNotEmpty && dTag.first[1] == _statsTag;
    });
    if (match.isEmpty) return;

    final account = _ndk.accounts.getLoggedAccount();
    if (account == null) return;

    final plaintext = await account.signer.decryptNip44(
      ciphertext: match.first.content,
      senderPubKey: pubkey,
    );
    if (plaintext == null) return;

    final json = jsonDecode(plaintext) as Map<String, dynamic>;
    _satsEarned = (json['sats_earned'] as num?)?.toInt() ?? 0;
    _lastPublishDate = json['last_publish_date'] as String?;
    _milestoneDates
      ..clear()
      ..addAll((json['milestone_dates'] as List?)?.cast<String>() ?? []);
    _loaded = true;
  }

  Future<void> _save() async {
    final pubkey = _ndk.accounts.getPublicKey();
    if (pubkey == null) return;

    final account = _ndk.accounts.getLoggedAccount();
    if (account == null) return;

    final plaintext = jsonEncode({
      'sats_earned': _satsEarned,
      'last_publish_date': _lastPublishDate,
      'milestone_dates': _milestoneDates.toList(),
    });

    final encrypted = await account.signer.encryptNip44(
      plaintext: plaintext,
      recipientPubKey: pubkey,
    );
    if (encrypted == null) return;

    final event = Nip01Event(
      pubKey: pubkey,
      kind: _statsKind,
      tags: [
        ['d', _statsTag],
      ],
      content: encrypted,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    _ndk.broadcast.broadcast(
      nostrEvent: event,
      specificRelays: NostrService.broadcastRelays,
    );
  }

  void recordMilestone() {
    _milestoneDates.add(_today());
    unawaited(_save());
  }

  void recordBookCompleted() {
    unawaited(_save());
  }

  void addSats(int amount) {
    _satsEarned += amount;
    unawaited(_save());
  }

  Future<void> publishDailyHeartbeat() async {
    final today = _today();
    if (_lastPublishDate == today) return;
    final pubkey = _ndk.accounts.getPublicKey();
    if (pubkey == null) return;

    final content = jsonEncode({
      'streak': streak,
      'books_read': booksRead,
      'sats_earned': satsEarned,
    });

    final event = Nip01Event(
      pubKey: pubkey,
      kind: _statsKind,
      tags: [
        ['d', 'zapbook:daily:$today'],
      ],
      content: content,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    _ndk.broadcast.broadcast(
      nostrEvent: event,
      specificRelays: NostrService.broadcastRelays,
    );

    _lastPublishDate = today;
    unawaited(_save());
  }

  String _today() => DateTime.now().toUtc().toIso8601String().substring(0, 10);

  String _dayOffset(int offset) {
    final d = DateTime.now().toUtc().add(Duration(days: offset));
    return d.toIso8601String().substring(0, 10);
  }

  String _dayBefore(String date) {
    final d = DateTime.parse(
      '${date}T00:00:00Z',
    ).subtract(const Duration(days: 1));
    return d.toIso8601String().substring(0, 10);
  }
}
