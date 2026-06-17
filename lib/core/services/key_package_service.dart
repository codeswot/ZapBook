import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:marmot_dart/marmot_dart.dart';
import 'package:ndk/ndk.dart';

import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/nostr_service.dart';

@lazySingleton
class KeyPackageService {
  KeyPackageService(this._marmot, this._identity, this._ndk);

  final Marmot _marmot;
  final IdentityLocalDataSource _identity;
  final Ndk _ndk;
  final _log = logging.Logger('KeyPackageService');

  static const _dTagKey = 'key_package_d_tag';
  static const _rotatedAtKey = 'key_package_rotated_at';
  static const _rotateAfter = Duration(days: 7);
  static const _keyPackageKind = 30443;

  Future<bool>? _activePublishFuture;

  final _keyPackageCache = <String, String>{};
  final _activeFetches = <String, Future<String?>>{};

  Future<String?> fetchKeyPackage(String npub) {
    if (_keyPackageCache.containsKey(npub)) {
      return Future.value(_keyPackageCache[npub]);
    }

    if (_activeFetches.containsKey(npub)) {
      return _activeFetches[npub]!;
    }

    final future = _fetchKeyPackageInternal(npub).whenComplete(() {
      _activeFetches.remove(npub);
    });

    _activeFetches[npub] = future;
    return future;
  }

  Future<String?> _fetchKeyPackageInternal(String npub) async {
    try {
      final hex = await MarmotIdentity.pubkeyHexFromNpub(npub);
      final response = _ndk.requests.query(
        filter: Filter(
          kinds: const [_keyPackageKind],
          authors: [hex],
          limit: 1,
        ),
        explicitRelays: NostrService.broadcastRelays,
      );
      final events = await response.future;
      if (events.isEmpty) return null;
      events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final json = _eventJson(events.first);
      _keyPackageCache[npub] = json;
      return json;
    } on Object catch (error, stack) {
      _log.warning('Failed to fetch key package for $npub', error, stack);
      return null;
    }
  }

  String _eventJson(Nip01Event event) => jsonEncode({
    'id': event.id,
    'pubkey': event.pubKey,
    'created_at': event.createdAt,
    'kind': event.kind,
    'tags': event.tags,
    'content': event.content,
    'sig': event.sig,
  });

  Future<bool> publishIfNeeded() {
    if (_activePublishFuture != null) return _activePublishFuture!;
    _activePublishFuture = _publishIfNeededInternal().whenComplete(() {
      _activePublishFuture = null;
    });
    return _activePublishFuture!;
  }

  Future<bool> _publishIfNeededInternal() async {
    final npub = await _identity.readNpub();
    final nsec = await _identity.readNsec();
    if (npub == null || nsec == null) return false;

    final dTag = await _identity.readDtag(_dTagKey);
    if (dTag == null) {
      return _publishInitial(nsec);
    }

    final lastStr = await _identity.readDtag(_rotatedAtKey);
    if (lastStr != null) {
      final last = DateTime.tryParse(lastStr);
      if (last != null && DateTime.now().difference(last) < _rotateAfter) {
        return true;
      }
    }

    return _rotate(nsec, dTag);
  }

  Future<bool> ensurePublished({int attempts = 3}) async {
    for (var attempt = 1; attempt <= attempts; attempt++) {
      if (await publishIfNeeded()) return true;
      if (attempt < attempts) {
        await Future<void>.delayed(Duration(seconds: attempt));
      }
    }
    _log.warning('Key package publish failed after $attempts attempts');
    return false;
  }

  Future<bool> forceRotate() {
    if (_activePublishFuture != null) return _activePublishFuture!;
    _activePublishFuture = _forceRotateInternal().whenComplete(() {
      _activePublishFuture = null;
    });
    return _activePublishFuture!;
  }

  Future<bool> _forceRotateInternal() async {
    final npub = await _identity.readNpub();
    final nsec = await _identity.readNsec();
    if (npub == null || nsec == null) return false;

    final dTag = await _identity.readDtag(_dTagKey);
    if (dTag == null) {
      return _publishInitial(nsec);
    } else {
      return _rotate(nsec, dTag);
    }
  }

  Future<bool> _publishInitial(String nsec) async {
    try {
      final signed = await _marmot.createSignedKeyPackage(
        nsec,
        NostrService.broadcastRelays,
      );

      final dTag = _extractDTag(signed);
      await _identity.writeDtag(_dTagKey, dTag);
      await _identity.writeDtag(
        _rotatedAtKey,
        DateTime.now().toIso8601String(),
      );

      _broadcast(signed);
      _log.info('Key package published (initial)');
      return true;
    } on Object catch (error, stack) {
      _log.warning('Failed to publish initial key package', error, stack);
      return false;
    }
  }

  Future<bool> _rotate(String nsec, String dTag) async {
    try {
      final npub = await _identity.readNpub();
      if (npub == null) return false;

      final kp = await _marmot.createKeyPackage(
        npub,
        NostrService.broadcastRelays,
      );

      final pubkey = await MarmotIdentity.pubkeyHexFromNpub(npub);
      final unsigned = _assembleUnsigned(
        content: kp.content,
        dTag: dTag,
        tags30443: kp.tags30443,
        pubkey: pubkey,
      );

      final signed = await signEvent(nsec, unsigned);
      await _identity.writeDtag(
        _rotatedAtKey,
        DateTime.now().toIso8601String(),
      );

      _broadcast(signed);
      _log.info('Key package rotated');
      return true;
    } on Object catch (error, stack) {
      _log.warning('Failed to rotate key package', error, stack);
      return false;
    }
  }

  void _broadcast(String eventJson) {
    try {
      final map = jsonDecode(eventJson) as Map<String, dynamic>;
      final tags = (map['tags'] as List)
          .map((t) => (t as List).map((e) => e.toString()).toList())
          .toList();

      _ndk.broadcast.broadcast(
        nostrEvent: Nip01Event(
          id: map['id'] as String,
          pubKey: map['pubkey'] as String,
          kind: (map['kind'] as num).toInt(),
          tags: tags,
          content: map['content'] as String,
          sig: map['sig'] as String?,
          createdAt: (map['created_at'] as num).toInt(),
        ),
        specificRelays: NostrService.broadcastRelays,
      );
    } on Object catch (error, stack) {
      _log.warning('Key package broadcast failed', error, stack);
    }
  }

  String _extractDTag(String signedEventJson) {
    final map = jsonDecode(signedEventJson) as Map<String, dynamic>;
    final tags = map['tags'] as List;
    for (final tag in tags) {
      final t = tag as List;
      if (t.isNotEmpty && t[0] == 'd') return t[1] as String;
    }
    throw StateError('No d tag found in key package event');
  }

  String _assembleUnsigned({
    required String content,
    required String dTag,
    required List<List<String>> tags30443,
    required String pubkey,
  }) {
    final tags = <List<String>>[
      ['d', dTag],
      ...tags30443,
    ];
    final event = {
      'pubkey': pubkey,
      'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'kind': 30443,
      'tags': tags,
      'content': content,
    };
    return jsonEncode(event);
  }
}
