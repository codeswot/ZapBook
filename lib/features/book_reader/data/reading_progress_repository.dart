import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart';
import 'package:reading_progress/reading_progress.dart';

import 'package:zapbook/core/data/cache/nostr_cache_store.dart';
import 'package:zapbook/core/services/nostr_service.dart';

@lazySingleton
class ReadingProgressRepository {
  ReadingProgressRepository(this._ndk, this._cache);

  final Ndk _ndk;
  final NostrCacheStore _cache;

  static const _kind = 30078;

  Future<void> saveSnapshot(
    String bookId,
    ReadingState state, {
    double? scrollOffset,
  }) async {
    final pubkey = _ndk.accounts.getPublicKey();
    if (pubkey == null) return;

    final account = _ndk.accounts.getLoggedAccount();
    if (account == null) return;

    final json = _stateToJson(state);
    if (scrollOffset != null) {
      json['_scroll_offset'] = scrollOffset;
    }
    final plaintext = jsonEncode(json);
    final encrypted = await account.signer.encryptNip44(
      plaintext: plaintext,
      recipientPubKey: pubkey,
    );
    if (encrypted == null) return;

    final event = Nip01Event(
      pubKey: pubkey,
      kind: _kind,
      tags: [
        ['d', bookId],
      ],
      content: encrypted,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    await account.signer.sign(event);

    _cache.saveEvent(event);

    _ndk.broadcast.broadcast(
      nostrEvent: event,
      specificRelays: NostrService.broadcastRelays,
    );
  }

  Future<({ReadingState state, double? scrollOffset})?> loadSnapshot(
    String bookId,
  ) async {
    final pubkey = _ndk.accounts.getPublicKey();
    if (pubkey == null) return null;

    final events = _cache.loadEvents(pubKeys: [pubkey], kinds: [_kind]);

    final match = events.where((e) {
      final dTag = e.tags.where((t) => t.length >= 2 && t[0] == 'd');
      return dTag.isNotEmpty && dTag.first[1] == bookId;
    });

    if (match.isEmpty) return null;

    final account = _ndk.accounts.getLoggedAccount();
    if (account == null) return null;

    final plaintext = await account.signer.decryptNip44(
      ciphertext: match.first.content,
      senderPubKey: pubkey,
    );
    if (plaintext == null) return null;

    final json = jsonDecode(plaintext) as Map<String, dynamic>;
    final scrollOffset = (json['_scroll_offset'] as num?)?.toDouble();
    return (state: _stateFromJson(json), scrollOffset: scrollOffset);
  }

  Map<String, dynamic> _stateToJson(ReadingState state) => {
    'wpm': state.wpm,
    'completed_pages': state.completedPages.toList(),
    'visited_pages': state.visitedPages.toList(),
    'partials': {
      for (final entry in state.partials.entries)
        entry.key.toString(): {
          'engaged_ms': entry.value.engagedMs,
          'scroll_samples': entry.value.scrollSamples,
          'skim_samples': entry.value.skimSamples,
        },
    },
    'words_read': state.wordsRead,
    'points_banked': state.pointsBanked,
    'milestones_reached': state.milestonesReached,
    'session_engaged_ms': state.sessionEngagedMs,
    'current_page': state.currentPage,
    'book_completed': state.bookCompleted,
  };

  ReadingState _stateFromJson(Map<String, dynamic> json) {
    final partialsJson = json['partials'] as Map<String, dynamic>? ?? {};
    final partials = <int, PagePartial>{};
    for (final entry in partialsJson.entries) {
      final v = entry.value as Map<String, dynamic>;
      partials[int.parse(entry.key)] = PagePartial(
        engagedMs: v['engaged_ms'] as int,
        scrollSamples: v['scroll_samples'] as int,
        skimSamples: v['skim_samples'] as int,
      );
    }

    return ReadingState(
      wpm: (json['wpm'] as num?)?.toDouble() ?? 240,
      completedPages:
          (json['completed_pages'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toSet() ??
          {},
      visitedPages:
          (json['visited_pages'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toSet() ??
          {},
      partials: partials,
      wordsRead: (json['words_read'] as num?)?.toInt() ?? 0,
      pointsBanked: (json['points_banked'] as num?)?.toInt() ?? 0,
      milestonesReached: (json['milestones_reached'] as num?)?.toInt() ?? 0,
      sessionEngagedMs: (json['session_engaged_ms'] as num?)?.toInt() ?? 0,
      currentPage: json['current_page'] as int?,
      bookCompleted: json['book_completed'] as bool? ?? false,
      open: null,
    );
  }
}
