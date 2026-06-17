import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:marmot_dart/marmot_dart.dart';
import 'package:ndk/ndk.dart';

import 'package:zapbook/core/domain/book_group_naming.dart';
import 'package:zapbook/core/extensions/nip01_event_extension.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/key_package_service.dart';
import 'package:zapbook/core/services/milestone_service.dart';
import 'package:zapbook/core/services/nostr_service.dart';
import 'package:zapbook/features/library/domain/repositories/library_repository.dart';

@lazySingleton
class MarmotSyncService {
  MarmotSyncService(
    this._marmot,
    this._ndk,
    this._identity,
    this._library,
    this._milestone,
    this._keyPackages,
  );

  final Marmot _marmot;
  final Ndk _ndk;
  final IdentityLocalDataSource _identity;
  final LibraryRepository _library;
  final MilestoneService _milestone;
  final KeyPackageService _keyPackages;
  final _log = logging.Logger('MarmotSyncService');

  static const _giftWrapKind = 1059;
  static const _groupMessageKind = 445;
  static const _debounce = Duration(milliseconds: 600);

  bool _running = false;
  String? _selfNpub;
  StreamSubscription<Nip01Event>? _welcomeSub;
  String? _welcomeSubId;
  StreamSubscription<Nip01Event>? _groupSub;
  String? _groupSubId;

  Timer? _refreshTimer;
  Timer? _heavyUpdateTimer;

  final _welcomeQueue = <Nip01Event>[];
  bool _processingWelcome = false;

  Future<void> start() async {
    if (_running) return;
    final npub = await _identity.readNpub();
    if (npub == null || npub.isEmpty) return;
    _running = true;
    _selfNpub = npub;
    try {
      final hex = await MarmotIdentity.pubkeyHexFromNpub(npub);
      _startWelcomeSub(hex);
      await _startGroupSub();
      _log.info('Live sync started');
    } on Object catch (error, stack) {
      _log.warning('Sync start failed', error, stack);
    }
  }

  Future<void> stop() async {
    _running = false;
    _refreshTimer?.cancel();
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

  void _startWelcomeSub(String hex) {
    final response = _ndk.requests.subscription(
      filter: Filter(kinds: const [_giftWrapKind], pTags: [hex]),
      explicitRelays: NostrService.broadcastRelays,
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
      final rumor = await _ndk.giftWrap.fromGiftWrap(giftWrap: giftWrap);
      await _marmot.processWelcome(giftWrap.id, rumor.toJsonString());
      for (final welcome in await _marmot.getPendingWelcomes()) {
        try {
          final rumor = await _ndk.giftWrap.fromGiftWrap(giftWrap: giftWrap);
          await _marmot.processWelcome(giftWrap.id, _eventJson(rumor));
          for (final welcome in await _marmot.getPendingWelcomes()) {
            try {
              await _marmot.acceptWelcome(welcome.id);
            } on Object catch (_) {
              if (await _purgeStaleGroup(welcome.groupName)) {
                try {
                  await _marmot.acceptWelcome(welcome.id);
                } on Object catch (_) {}
              }
            }
          }
          processedAny = true;
        } on Object catch (error) {
          _log.fine('Welcome event skipped: $error');
        }
      }

      if (processedAny) {
        _scheduleHeavyUpdates();
      }
    } finally {
      _processingWelcome = false;
    }
  }

  void _scheduleHeavyUpdates() {
    _heavyUpdateTimer?.cancel();
    _heavyUpdateTimer = Timer(_debounce, () {
      unawaited(_executeHeavyUpdates());
    });
  }

  Future<void> _executeHeavyUpdates() async {
    try {
      await _keyPackages.forceRotate();
      await _restartGroupSub();
      _scheduleRefresh();
    } on Object catch (error, stack) {
      _log.warning('Heavy updates failed', error, stack);
    }
  }

  Future<bool> _purgeStaleGroup(String groupName) async {
    final self = _selfNpub;
    try {
      for (final group in await _marmot.listGroups()) {
        if (group.name != groupName) continue;
        if (self != null) {
          final members = await _marmot.getMembers(group.id);
          if (members.any((member) => member.npub == self)) return false;
        }
        await _marmot.deleteGroup(group.id);
        return true;
      }
    } on Object catch (error, stack) {
      _log.warning('Purge stale group failed for $groupName', error, stack);
    }
    return false;
  }

  Future<void> _startGroupSub() async {
    final groups = await _marmot.listGroups();
    final ids = groups
        .where((group) => BookGroupNaming.matches(group.name))
        .map((group) => group.nostrGroupId)
        .toList(growable: false);
    if (ids.isEmpty) return;

    final response = _ndk.requests.subscription(
      filter: Filter(kinds: const [_groupMessageKind], tags: {'#h': ids}),
      explicitRelays: NostrService.broadcastRelays,
    );
    _groupSubId = response.requestId;
    _groupSub = response.stream.listen(_onGroupMessage);
  }

  Future<void> _restartGroupSub() async {
    await _groupSub?.cancel();
    final groupId = _groupSubId;
    if (groupId != null) await _ndk.requests.closeSubscription(groupId);
    _groupSub = null;
    _groupSubId = null;
    await _startGroupSub();
  }

  Future<void> _onGroupMessage(Nip01Event event) async {
    try {
      final message = await _marmot.processIncoming(event.toJsonString());
      if (message != null) _milestone.ingestMessage(message);
    } on Object catch (error) {
      _log.fine('processIncoming skipped: $error');
    }
    _scheduleRefresh();
  }

  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(_debounce, () {
      unawaited(
        _library.refresh().catchError(
          (Object error, StackTrace stack) =>
              _log.warning('Library refresh failed', error, stack),
        ),
      );
    });
  }
}
