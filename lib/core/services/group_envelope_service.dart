import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:ndk/ndk.dart';
import 'package:zapbook/core/config/zapbook_config.dart';

@lazySingleton
class GroupEnvelopeService {
  GroupEnvelopeService(this._ndk);

  final Ndk _ndk;
  final _log = logging.Logger('GroupEnvelopeService');

  static const _relays = ZapbookConfig.broadcastRelays;

  Future<void> publish(String eventJson) async {
    try {
      final response = _ndk.broadcast.broadcast(
        nostrEvent: _toNip01Event(eventJson),
        specificRelays: _relays,
      );
      await response.broadcastDoneFuture.timeout(const Duration(seconds: 3));
    } on Object catch (error, stack) {
      _log.warning('Relay publish failed or timed out', error, stack);
    }
  }

  Future<void> giftWrapAndPublish(String rumorJson, String recipientHex) async {
    try {
      final rumor = _toNip01Event(rumorJson);
      final wrap = await _ndk.giftWrap.toGiftWrap(
        rumor: rumor,
        recipientPubkey: recipientHex,
      );
      _ndk.broadcast.broadcast(nostrEvent: wrap, specificRelays: _relays);
    } on Object catch (error, stack) {
      _log.warning('Gift-wrap welcome failed', error, stack);
    }
  }

  static Nip01Event _toNip01Event(String eventJson) {
    final map = jsonDecode(eventJson) as Map<String, dynamic>;
    final tags = (map['tags'] as List)
        .map((tag) => (tag as List).map((e) => e.toString()).toList())
        .toList();
    return Nip01Event(
      id: map['id'] as String?,
      pubKey: map['pubkey'] as String,
      kind: (map['kind'] as num).toInt(),
      tags: tags,
      content: map['content'] as String,
      sig: map['sig'] as String?,
      createdAt: (map['created_at'] as num).toInt(),
    );
  }
}
