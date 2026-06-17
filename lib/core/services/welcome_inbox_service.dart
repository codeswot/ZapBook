import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:marmot_dart/marmot_dart.dart';
import 'package:ndk/ndk.dart';

import 'package:zapbook/core/extensions/nip01_event_extension.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/nostr_service.dart';

@lazySingleton
class WelcomeInboxService {
  WelcomeInboxService(this._marmot, this._ndk, this._identity) {
    _start();
  }

  final Marmot _marmot;
  final Ndk _ndk;
  final IdentityLocalDataSource _identity;
  final _log = logging.Logger('WelcomeInboxService');

  static const _giftWrapKind = 1059;
  final _onJoinedController = StreamController<int>.broadcast();

  bool _isSyncing = false;
  int? _lastSyncTimestamp;

  Stream<int> get onJoined => _onJoinedController.stream;

  void _start() {
    _syncLoop();
  }

  Future<void> _syncLoop() async {
    if (_isSyncing) return;

    try {
      final joined = await sync();
      if (joined > 0) _onJoinedController.add(joined);
    } on Object catch (error, stack) {
      _log.warning('Welcome sync loop error', error, stack);
    }
  }

  Future<int> sync() async {
    if (_isSyncing) return 0;

    final npub = await _identity.readNpub();
    if (npub == null || npub.isEmpty) return 0;

    _isSyncing = true;
    var joined = 0;

    try {
      final nextSyncTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final hex = await MarmotIdentity.pubkeyHexFromNpub(npub);

      final filter = Filter(
        kinds: const [_giftWrapKind],
        pTags: [hex],
        since: _lastSyncTimestamp,
      );

      final wraps = await _ndk.requests
          .query(filter: filter, explicitRelays: NostrService.broadcastRelays)
          .future;

      for (final wrap in wraps) {
        try {
          final rumor = await _ndk.giftWrap.fromGiftWrap(giftWrap: wrap);
          await _marmot.processWelcome(wrap.id, rumor.toMarmotJson());
        } on Object catch (error) {
          _log.fine('Skipping gift-wrap ${wrap.id}: $error');
        }
      }

      final pending = await _marmot.getPendingWelcomes();
      for (final welcome in pending) {
        try {
          await _marmot.acceptWelcome(welcome.id);
          joined++;
        } on Object catch (error) {
          _log.fine('Accept welcome ${welcome.id} failed: $error');
        }
      }

      if (joined > 0) _log.info('Joined $joined group(s) from welcomes');

      _lastSyncTimestamp = nextSyncTimestamp;
    } on Object catch (error, stack) {
      _log.warning('Welcome inbox sync failed', error, stack);
    } finally {
      _isSyncing = false;
    }

    return joined;
  }


  @disposeMethod
  void dispose() {
    _onJoinedController.close();
  }
}
