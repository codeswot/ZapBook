import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:marmot_dart/marmot_dart.dart';
import 'package:ndk/ndk.dart';
import 'package:zapbook/core/config/zapbook_config.dart';

import 'package:zapbook/core/extensions/nip01_event_extension.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';

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

  Future<String?> fetchKeyPackage(String npub, {bool forceRefresh = false}) {
    if (!forceRefresh && _keyPackageCache.containsKey(npub)) {
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
        explicitRelays: ZapbookConfig.broadcastRelays,
      );
      final events = await response.future;
      if (events.isEmpty) return null;
      events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final json = events.first.toMarmotJson();
      _keyPackageCache[npub] = json;
      return json;
    } on Object catch (error, stack) {
      _log.warning('Failed to fetch key package for $npub', error, stack);
      return null;
    }
  }

  Future<bool> publishIfNeeded() {
    if (_activePublishFuture != null) return _activePublishFuture!;
    _activePublishFuture = _publishIfNeededInternal().whenComplete(() {
      _activePublishFuture = null;
    });
    return _activePublishFuture!;
  }

  Future<bool> _publishIfNeededInternal() async {
    final npub = await _identity.readNpub();
    if (npub == null) return false;

    final dTag = await _identity.readDtag(_dTagKey);
    if (dTag == null) {
      return _publish(npub, existingDtag: null);
    }

    final lastStr = await _identity.readDtag(_rotatedAtKey);
    if (lastStr != null) {
      final last = DateTime.tryParse(lastStr);
      if (last != null && DateTime.now().difference(last) < _rotateAfter) {
        return true;
      }
    }

    return _publish(npub, existingDtag: dTag);
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
    if (npub == null) return false;
    final dTag = await _identity.readDtag(_dTagKey);
    return _publish(npub, existingDtag: dTag);
  }

  Future<bool> _publish(String npub, {required String? existingDtag}) async {
    final account = _ndk.accounts.getLoggedAccount();
    if (account == null || !account.signer.canSign()) {
      _log.warning('No signer available to publish key package');
      return false;
    }

    try {
      final kp = await _marmot.createKeyPackage(
        npub,
        ZapbookConfig.broadcastRelays,
      );
      final dTag = existingDtag ?? kp.dTag;

      final unsigned = Nip01Event(
        pubKey: account.signer.getPublicKey(),
        kind: _keyPackageKind,
        tags: [
          ['d', dTag],
          ...kp.tags30443,
        ],
        content: kp.content,
      );

      final signed = await account.signer.sign(unsigned);
      _ndk.broadcast.broadcast(
        nostrEvent: signed,
        specificRelays: ZapbookConfig.broadcastRelays,
      );

      if (existingDtag == null) {
        await _identity.writeDtag(_dTagKey, dTag);
      }
      await _identity.writeDtag(
        _rotatedAtKey,
        DateTime.now().toIso8601String(),
      );

      _log.info(
        existingDtag == null ? 'Key package published (initial)' : 'Key package rotated',
      );
      return true;
    } on Object catch (error, stack) {
      _log.warning('Failed to publish key package', error, stack);
      return false;
    }
  }
}
