import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;

import 'package:marmot_dart/marmot_dart.dart';
import 'package:ndk/ndk.dart';
import 'package:zapbook/core/config/zapbook_config.dart';

import 'package:zapbook/core/extensions/nip01_event_extension.dart';
import 'package:zapbook/core/domain/book_group_naming.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/key_package_service.dart';

@lazySingleton
class MarmotSyncService {
  MarmotSyncService(this._marmot, this._ndk, this._identity, this._keyPackages);

  final Marmot _marmot;
  final Ndk _ndk;
  final IdentityLocalDataSource _identity;
  final KeyPackageService _keyPackages;
  final _log = logging.Logger('MarmotSyncService');

  static const _giftWrapKind = 1059;
  static const _groupMessageKind = 445;
  static const _debounce = Duration(milliseconds: 600);

  bool _running = false;

  StreamSubscription<Nip01Event>? _welcomeSub;
  String? _welcomeSubId;
  StreamSubscription<Nip01Event>? _groupSub;
  String? _groupSubId;

  Timer? _heavyUpdateTimer;

  final _messageController = StreamController<MarmotMessage>.broadcast();
  Stream<MarmotMessage> get onMessage => _messageController.stream;

  final _groupController = StreamController<MarmotGroup>.broadcast();
  Stream<MarmotGroup> get onGroup => _groupController.stream;

  final _syncController = StreamController<void>.broadcast();
  Stream<void> get onSync => _syncController.stream;

  final _welcomeQueue = <Nip01Event>[];
  bool _processingWelcome = false;
  bool _isExecutingHeavyUpdates = false;
  bool _heavyUpdatePending = false;

  Future<void> start() async {
    if (_running) return;
    final npub = await _identity.readNpub();
    if (npub == null || npub.isEmpty) return;
    _running = true;
    try {
      final hex = await MarmotIdentity.pubkeyHexFromNpub(npub);
      _startWelcomeSub(hex);
      await _startGroupSub();
      _log.info('Live sync started');
    } on Object catch (error, stack) {
      _log.warning('Sync start failed', error, stack);
    }
  }

  void _startWelcomeSub(String hex) {
    final response = _ndk.requests.subscription(
      filter: Filter(kinds: const [_giftWrapKind], pTags: [hex]),
      explicitRelays: ZapbookConfig.broadcastRelays,
    );
    _welcomeSubId = response.requestId;
    _welcomeSub = response.stream.listen(_onWelcome);
  }

  void _onWelcome(Nip01Event giftWrap) {
    _welcomeQueue.add(giftWrap);
    _processWelcomeQueue();
  }

  Future<void> _processWelcomeQueue() async {
    if (_processingWelcome) return;
    _processingWelcome = true;

    try {
      bool processedAny = false;
      while (_welcomeQueue.isNotEmpty) {
        final batch = _welcomeQueue.toList();
        _welcomeQueue.clear();

        for (final giftWrap in batch) {
          try {
            final rumor = await _ndk.giftWrap.fromGiftWrap(giftWrap: giftWrap);
            await _marmot.processWelcome(giftWrap.id, rumor.toMarmotJson());
            processedAny = true;
          } on Object catch (error) {
            _log.fine('Welcome event skipped: $error');
          }
        }
      }

      if (processedAny) {
        bool acceptedAny = false;
        final pendingWelcomes = await _marmot.getPendingWelcomes();

        for (final welcome in pendingWelcomes) {
          try {
            await _marmot.acceptWelcome(welcome.id);
            acceptedAny = true;
          } on Object catch (error, trace) {
            _log.warning('unable to accept welcome', error, trace);
          }
        }

        if (acceptedAny) {
          _log.info(
            'Scheduling heavy updates from welcome queue (acceptedAny = true)',
          );
          _syncController.add(null);
          _scheduleHeavyUpdates();
        }
      }
    } finally {
      _processingWelcome = false;
    }
  }

  void _scheduleHeavyUpdates() {
    _heavyUpdateTimer?.cancel();
    _heavyUpdateTimer = Timer(_debounce, () {
      if (_isExecutingHeavyUpdates) {
        _heavyUpdatePending = true;
      } else {
        unawaited(_executeHeavyUpdates());
      }
    });
  }

  Future<void> _executeHeavyUpdates() async {
    if (_isExecutingHeavyUpdates) return;
    _isExecutingHeavyUpdates = true;
    _heavyUpdatePending = false;
    try {
      await _keyPackages.forceRotate();
      await _restartGroupSub();
    } on Object catch (error, stack) {
      _log.warning('Heavy updates failed', error, stack);
    } finally {
      _isExecutingHeavyUpdates = false;
      if (_heavyUpdatePending) {
        unawaited(_executeHeavyUpdates());
      }
    }
  }

  Future<void> _startGroupSub() async {
    final groups = await _marmot.listGroups();
    final bookGroups = groups
        .where((group) => BookGroupNaming.matches(group.name))
        .toList();

    final ids = bookGroups
        .map((group) => group.nostrGroupId)
        .toList(growable: false);
    if (ids.isEmpty) return;

    int? since;
    if (bookGroups.any((g) => g.lastMessageProcessedAtSecs == null)) {
      since = null;
    } else if (bookGroups.isNotEmpty) {
      since = bookGroups
          .map((g) => g.lastMessageProcessedAtSecs ?? 0)
          .reduce((a, b) => a < b ? a : b);
      since = since - 300;
    }

    final response = _ndk.requests.subscription(
      filter: Filter(
        kinds: const [_groupMessageKind],
        tags: {'#h': ids},
        since: since,
      ),
      explicitRelays: ZapbookConfig.broadcastRelays,
    );
    _groupSubId = response.requestId;
    _groupSub = response.stream.listen(_onGroupEvent);
  }

  Future<void> _restartGroupSub() async {
    await _groupSub?.cancel();
    final subId = _groupSubId;
    if (subId != null) await _ndk.requests.closeSubscription(subId);
    _groupSub = null;
    _groupSubId = null;
    await _startGroupSub();
  }

  Future<void> _onGroupEvent(Nip01Event event) async {
    try {
      final message = await _marmot.processIncoming(event.toMarmotJson());
      if (message != null) {
        _messageController.add(message);
      } else {
        final groupIdHex = event.getTags('h').firstOrNull;
        if (groupIdHex != null) {
          final groups = await _marmot.listGroups();
          final group = groups
              .where((g) => g.nostrGroupId == groupIdHex)
              .firstOrNull;

          if (group != null) {
            _groupController.add(group);
          }
        }
      }
    } on Object catch (error) {
      _log.fine('processIncoming skipped: $error');
    }
  }

  Future<void> stop() async {
    _running = false;
    _heavyUpdateTimer?.cancel();
    _welcomeQueue.clear();
    await _welcomeSub?.cancel();
    await _groupSub?.cancel();
    final welcomeId = _welcomeSubId;
    final groupId = _groupSubId;
    if (welcomeId != null) await _ndk.requests.closeSubscription(welcomeId);
    if (groupId != null) await _ndk.requests.closeSubscription(groupId);
    _welcomeSub = null;
    _groupSub = null;
    _welcomeSubId = null;
    _groupSubId = null;
  }
}
