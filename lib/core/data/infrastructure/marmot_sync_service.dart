import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;

import 'package:marmot_dart/marmot_dart.dart';
import 'package:ndk/ndk.dart';
import 'package:zapbook/core/config/zapbook_config.dart';

import 'package:zapbook/core/extensions/nip01_event_extension.dart';
import 'package:zapbook/core/domain/book_group_naming.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/data/infrastructure/key_package_service.dart';

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
  final _groupSubs = <String, StreamSubscription<Nip01Event>>{};
  final _groupSubIds = <String, String>{};

  Timer? _heavyUpdateTimer;

  final _messageController = StreamController<MarmotMessage>.broadcast();
  Stream<MarmotMessage> get onMessage => _messageController.stream;

  final _groupController = StreamController<MarmotGroup>.broadcast();
  Stream<MarmotGroup> get onGroup => _groupController.stream;

  final _syncController = StreamController<void>.broadcast();
  Stream<void> get onSync => _syncController.stream;

  final _welcomeAcceptedController =
      StreamController<PendingWelcome>.broadcast();
  Stream<PendingWelcome> get onWelcomeAccepted =>
      _welcomeAcceptedController.stream;

  final _welcomeQueue = <Nip01Event>[];
  bool _processingWelcome = false;
  bool _isExecutingHeavyUpdates = false;
  bool _heavyUpdatePending = false;
  final _seenWelcomeIds = <String>{};
  final _seenGroupEventIds = <String>{};
  final _groupEventQueue = <Nip01Event>[];
  bool _processingGroupEvents = false;

  Future<void> start() async {
    if (_running) return;
    final npub = await _identity.readNpub();
    if (npub == null || npub.isEmpty) return;
    _running = true;
    try {
      final hex = await MarmotIdentity.pubkeyHexFromNpub(npub);
      _startWelcomeSub(hex);
      await _startGroupSubs();
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
    if (!_seenWelcomeIds.add(giftWrap.id)) return;
    if (_seenWelcomeIds.length > 200) {
      _seenWelcomeIds.remove(_seenWelcomeIds.first);
    }
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

        final decryptions = await Future.wait(
          batch.map((giftWrap) async {
            try {
              final rumor = await _ndk.giftWrap.fromGiftWrap(
                giftWrap: giftWrap,
              );
              return MapEntry(giftWrap.id, rumor);
            } on Object catch (error) {
              _log.fine('Welcome decryption failed: $error');
              return null;
            }
          }),
        );

        for (final entry in decryptions) {
          if (entry == null) continue;
          try {
            await _marmot.processWelcome(entry.key, entry.value.toMarmotJson());
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
            _welcomeAcceptedController.add(welcome);
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
      final groups = await _marmot.listGroups();
      for (final group in groups) {
        _groupController.add(group);
      }
      await _restartGroupSubs();
    } on Object catch (error, stack) {
      _log.warning('Heavy updates failed', error, stack);
    } finally {
      _isExecutingHeavyUpdates = false;
      if (_heavyUpdatePending) {
        unawaited(_executeHeavyUpdates());
      }
    }
  }

  Future<void> _startGroupSubs() async {
    final groups = await _marmot.listGroups();
    final bookGroups = groups
        .where((group) => BookGroupNaming.matches(group.name))
        .toList();

    final activeIds = bookGroups.map((g) => g.id).toSet();

    final toRemove = _groupSubs.keys
        .where((id) => !activeIds.contains(id))
        .toList();
    for (final id in toRemove) {
      _stopGroupSub(id);
    }

    for (final group in bookGroups) {
      final groupId = group.id;
      final nostrGroupId = group.nostrGroupId;
      if (_groupSubs.containsKey(groupId)) continue;

      int? since;
      if (group.lastMessageProcessedAtSecs == null) {
        since = null;
      } else {
        since = (group.lastMessageProcessedAtSecs ?? 0) - 300;
      }

      final response = _ndk.requests.subscription(
        filter: Filter(
          kinds: const [_groupMessageKind],
          tags: {
            '#h': [nostrGroupId],
          },
          since: since,
        ),
        explicitRelays: ZapbookConfig.broadcastRelays,
      );
      _groupSubIds[groupId] = response.requestId;
      _groupSubs[groupId] = response.stream.listen(_onGroupEvent);
    }
  }

  Future<void> _restartGroupSubs() async {
    await _startGroupSubs();
  }

  void _stopGroupSub(String groupId) {
    final sub = _groupSubs.remove(groupId);
    unawaited(sub?.cancel());
    final subId = _groupSubIds.remove(groupId);
    if (subId != null) {
      unawaited(_ndk.requests.closeSubscription(subId));
    }
  }

  void _onGroupEvent(Nip01Event event) {
    if (!_seenGroupEventIds.add(event.id)) return;
    if (_seenGroupEventIds.length > 250) {
      _seenGroupEventIds.remove(_seenGroupEventIds.first);
    }
    _groupEventQueue.add(event);
    _processGroupEventQueue();
  }

  Future<void> _processGroupEventQueue() async {
    if (_processingGroupEvents) return;
    _processingGroupEvents = true;

    try {
      while (_groupEventQueue.isNotEmpty) {
        final event = _groupEventQueue.removeAt(0);
        try {
          final result = await _marmot.processIncomingWithKind(
            event.toMarmotJson(),
          );
          if (result.message != null) {
            _messageController.add(result.message!);
          } else if (result.groupId != null) {
            final group = await _marmot.getGroup(result.groupId!);
            if (group != null) {
              _groupController.add(group);
            }
          }
        } on Object catch (error) {
          _log.fine('processIncoming skipped: $error');
        }
      }
    } finally {
      _processingGroupEvents = false;
    }
  }

  Future<void> stop() async {
    _running = false;
    _heavyUpdateTimer?.cancel();
    _welcomeQueue.clear();
    _groupEventQueue.clear();
    _seenWelcomeIds.clear();
    _seenGroupEventIds.clear();
    await _welcomeSub?.cancel();
    for (final sub in _groupSubs.values) {
      await sub.cancel();
    }
    _groupSubs.clear();
    for (final subId in _groupSubIds.values) {
      await _ndk.requests.closeSubscription(subId);
    }
    _groupSubIds.clear();
    final welcomeId = _welcomeSubId;
    if (welcomeId != null) await _ndk.requests.closeSubscription(welcomeId);
    _welcomeSub = null;
    _welcomeSubId = null;
  }
}
