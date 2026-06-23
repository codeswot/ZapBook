import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:marmot_dart/marmot_dart.dart';
import 'package:ndk/ndk.dart';

import 'package:zapbook/core/domain/book_group_naming.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/nostr_service.dart';
import 'package:zapbook/core/services/decoded_message_cache.dart';
import 'package:zapbook/core/extensions/string_extension.dart';

@lazySingleton
class ZapNudgeService {
  ZapNudgeService(this._marmot, this._ndk, this._identity, this._cache);

  final Marmot _marmot;
  final Ndk _ndk;
  final IdentityLocalDataSource _identity;
  final DecodedMessageCache _cache;

  static const _relays = NostrService.broadcastRelays;

  final _log = logging.Logger('ZapNudgeService');

  Future<void> nudgeForBook({
    required String bookId,
    required String toNpub,
  }) async {
    final groupId = await _resolveGroupId(bookId);
    if (groupId == null) return;
    await nudge(groupId: groupId, toNpub: toNpub);
  }

  Future<void> nudge({required String groupId, required String toNpub}) async {
    final npub = await _identity.readNpub();
    if (npub == null || npub.isEmpty) return;
    if (await _hasPendingNudge(groupId, npub, toNpub)) return;
    final nudgeId = '$npub:$toNpub:${DateTime.now().millisecondsSinceEpoch}';
    await _send(npub, groupId, {
      'type': 'zapbook.zap.nudge',
      'nudgeId': nudgeId,
      'fromNpub': npub,
      'fromName': await _myName(npub),
      'toNpub': toNpub,
      'createdAtMs': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> ready({
    required String groupId,
    required String nudgeId,
    required String toNpub,
  }) async {
    final npub = await _identity.readNpub();
    if (npub == null || npub.isEmpty) return;
    await _send(npub, groupId, {
      'type': 'zapbook.zap.ready',
      'nudgeId': nudgeId,
      'fromNpub': npub,
      'fromName': await _myName(npub),
      'toNpub': toNpub,
      'createdAtMs': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<bool> _hasPendingNudge(String groupId, String from, String to) async {
    try {
      final messages = await _marmot.getMessages(groupId);
      final pending = <String>{};
      final resolved = <String>{};
      for (final msg in messages) {
        if (!(msg.payloadJson ?? '').contains('zapbook.zap.')) continue;
        final decoded = _cache.get(msg);
        if (decoded == null) continue;
        final id = decoded['nudgeId'] as String? ?? '';
        if (decoded['type'] == 'zapbook.zap.nudge' &&
            decoded['fromNpub'] == from &&
            decoded['toNpub'] == to) {
          pending.add(id);
        } else if (decoded['type'] == 'zapbook.zap.ready') {
          resolved.add(id);
        }
      }
      pending.removeWhere(resolved.contains);
      return pending.isNotEmpty;
    } on Object {
      return false;
    }
  }

  Future<String> _myName(String npub) async {
    try {
      final hex = _ndk.accounts.getPublicKey();
      if (hex != null) {
        final meta = await _ndk.metadata.loadMetadata(hex);
        final displayName = meta?.displayName;
        if (displayName != null && displayName.isNotEmpty) return displayName;
        final name = meta?.name;
        if (name != null && name.isNotEmpty) return name;
      }
    } on Object catch (_) {}
    return npub.toNpubShort();
  }

  Future<void> _send(
    String npub,
    String groupId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final event = await _marmot.sendStructured(npub, groupId, payload);
      _publish(event);
    } on Object catch (error, stack) {
      _log.warning('Nudge send failed', error, stack);
    }
  }

  Future<String?> _resolveGroupId(String bookId) async {
    final name = BookGroupNaming.nameFor(bookId);
    final groups = await _marmot.listGroups();
    for (final group in groups) {
      if (group.name == name) return group.id;
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
