import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:ndk/ndk.dart';
import 'package:zapbook/core/config/zapbook_config.dart';
import 'package:zapbook/core/data/cache/nostr_cache_store.dart';
import 'package:zapbook/features/book_reader/domain/entities/highlight.dart';

@lazySingleton
class HighlightPrivateSyncService {
  HighlightPrivateSyncService(this._ndk, this._cache);

  final Ndk _ndk;
  final NostrCacheStore _cache;
  final _log = logging.Logger('HighlightPrivateSyncService');

  static const _kind = 30078;
  static const _tagPrefix = 'zbhighlight_';

  Future<void> publish(Highlight highlight) async {
    final pubkey = _ndk.accounts.getPublicKey();
    if (pubkey == null) return;

    final account = _ndk.accounts.getLoggedAccount();
    if (account == null) return;

    try {
      final plaintext = jsonEncode(_toJson(highlight));
      final encrypted = await account.signer.encryptNip44(
        plaintext: plaintext,
        recipientPubKey: pubkey,
      );
      if (encrypted == null) return;

      final event = Nip01Event(
        pubKey: pubkey,
        kind: _kind,
        tags: [
          ['d', '$_tagPrefix${highlight.id}'],
        ],
        content: encrypted,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );

      _ndk.broadcast.broadcast(
        nostrEvent: event,
        specificRelays: ZapbookConfig.broadcastRelays,
      );
    } on Object catch (error, stack) {
      _log.warning('Failed to publish private highlight', error, stack);
    }
  }

  Future<List<Highlight>> loadAll() async {
    final pubkey = _ndk.accounts.getPublicKey();
    if (pubkey == null) return const [];

    final account = _ndk.accounts.getLoggedAccount();
    if (account == null) return const [];

    final events = _cache.loadEvents(pubKeys: [pubkey], kinds: [_kind]);
    final matches = events.where((e) {
      final dTag = e.tags.where((t) => t.length >= 2 && t[0] == 'd');
      return dTag.isNotEmpty && dTag.first[1].startsWith(_tagPrefix);
    });

    final result = <Highlight>[];
    for (final event in matches) {
      try {
        final plaintext = await account.signer.decryptNip44(
          ciphertext: event.content,
          senderPubKey: pubkey,
        );
        if (plaintext == null) continue;
        result.add(_fromJson(jsonDecode(plaintext) as Map<String, dynamic>));
      } on Object catch (error, stack) {
        _log.warning('Failed to decrypt private highlight', error, stack);
      }
    }
    return result;
  }

  Map<String, dynamic> _toJson(Highlight highlight) => {
    'v': 1,
    'id': highlight.id,
    'bookId': highlight.bookId,
    'ownerNpub': highlight.ownerNpub,
    'visibility': highlight.visibility.name,
    'groupId': highlight.groupId,
    'pageNumber': highlight.pageNumber,
    'spans': highlight.spans.map((s) => s.toJson()).toList(),
    'quoteSnapshot': highlight.quoteSnapshot,
    'note': highlight.note,
    'createdAt': highlight.createdAt.millisecondsSinceEpoch,
    'updatedAt': highlight.updatedAt.millisecondsSinceEpoch,
    'deleted': highlight.deleted,
  };

  Highlight _fromJson(Map<String, dynamic> json) => Highlight(
    id: json['id'] as String,
    bookId: json['bookId'] as String,
    ownerNpub: json['ownerNpub'] as String,
    visibility: HighlightVisibility.values.byName(json['visibility'] as String),
    groupId: json['groupId'] as String?,
    pageNumber: json['pageNumber'] as int,
    spans: (json['spans'] as List<dynamic>)
        .map((s) => HighlightSpan.fromJson(s as Map<String, dynamic>))
        .toList(),
    quoteSnapshot: json['quoteSnapshot'] as String,
    note: json['note'] as String?,
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
    deleted: json['deleted'] as bool,
  );
}
