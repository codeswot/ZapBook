import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:marmot_dart/marmot_dart.dart';
import 'package:ndk/ndk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zapbook/core/data/database/dao/zap_sats_earnings_dao.dart';
import 'package:zapbook/core/domain/book_group_naming.dart';
import 'package:zapbook/core/data/infrastructure/contact_service.dart';
import 'package:zapbook/core/data/infrastructure/local_notification_service.dart';
import 'package:zapbook/core/data/infrastructure/marmot_sync_service.dart';
import 'package:zapbook/core/data/infrastructure/message_router_service.dart';
import 'package:zapbook/core/data/infrastructure/sync_service_channel.dart';
import 'package:zapbook/core/data/infrastructure/zap_earnings_service.dart';
import 'package:zapbook/core/domain/entities/cheers_activity_message.dart';
import 'package:zapbook/core/domain/entities/cheers_activity_type.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';

@lazySingleton
class NotificationGate {
  NotificationGate(
    this._router,
    this._marmotSync,
    this._earnings,
    this._notifications,
    this._serviceChannel,
    this._contacts,
    this._identity,
  );

  static const enabledPrefKey = 'background_sync_enabled';
  static const _watermarkPrefKey = 'notif_watermark_secs';

  final MessageRouterService _router;
  final MarmotSyncService _marmotSync;
  final ZapEarningsService _earnings;
  final LocalNotificationService _notifications;
  final SyncServiceChannel _serviceChannel;
  final ContactService _contacts;
  final IdentityLocalDataSource _identity;

  final _log = logging.Logger('NotificationGate');
  final _subs = <StreamSubscription<Object?>>[];
  final _seenIds = <String>{};

  SharedPreferences? _prefs;
  String? _selfNpub;
  bool _initialized = false;
  int _cutoffSecs = 0;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _prefs = await SharedPreferences.getInstance();
    _selfNpub = await _identity.readNpub();

    if (_prefs?.getInt(_watermarkPrefKey) == null) {
      await _setWatermark(_nowSecs());
    }
    _cutoffSecs = _watermark;

    _subs.add(_router.onActivity.listen(_onActivity));
    _subs.add(_marmotSync.onWelcomeAccepted.listen(_onWelcomeAccepted));
    _subs.add(_earnings.onZap.listen(_onZap));

    if (isEnabled) {
      await _notifications.init();
      await _serviceChannel.start();
    }
  }

  bool get isEnabled => _prefs?.getBool(enabledPrefKey) ?? false;

  Future<void> setEnabled(bool value) async {
    await _prefs?.setBool(enabledPrefKey, value);
    if (value) {
      await _setWatermark(_nowSecs());
      _cutoffSecs = _watermark;
      await _serviceChannel.start();
    } else {
      await _serviceChannel.stop();
    }
  }

  Future<void> _onActivity(CheersActivityMessage activity) async {
    final tsSecs = activity.timestamp.millisecondsSinceEpoch ~/ 1000;
    if (!_shouldNotify(id: activity.id, tsSecs: tsSecs)) return;
    if (activity.actorNpub == _selfNpub &&
        activity.type != CheersActivityType.adminAction) {
      return;
    }

    final name = _nameFor(activity.actorNpub);
    final circle = activity.bookTitle;
    final inCircle = circle == null || circle.isEmpty ? '' : ' · $circle';
    final (title, body, channel) = switch (activity.type) {
      CheersActivityType.milestone => (
        circle ?? 'Circle activity',
        '$name — ${activity.activityDescription}',
        ZapbookNotificationChannel.cheers,
      ),
      CheersActivityType.cheer => (
        'Cheers!',
        '$name ${activity.activityDescription}$inCircle',
        ZapbookNotificationChannel.cheers,
      ),
      CheersActivityType.zap => (
        'Zap sent',
        '$name zapped${_satsSuffix(activity.zapAmount)}$inCircle',
        ZapbookNotificationChannel.sats,
      ),
      CheersActivityType.zapNudge => (
        'Zap nudge',
        '$name wants to zap you — set up a lightning address',
        ZapbookNotificationChannel.sats,
      ),
      CheersActivityType.zapReady => (
        'Ready for zaps',
        '$name is now ready to receive zaps',
        ZapbookNotificationChannel.sats,
      ),
      CheersActivityType.adminAction => (
        'Action Required',
        activity.activityDescription,
        ZapbookNotificationChannel.circles,
      ),
      _ => (
        'ZapBook',
        activity.activityDescription,
        ZapbookNotificationChannel.cheers,
      ),
    };

    await _show(
      id: activity.id,
      title: title,
      body: body,
      channel: channel,
      tsSecs: tsSecs,
    );
  }

  Future<void> _onWelcomeAccepted(PendingWelcome welcome) async {
    if (!_shouldNotify(id: welcome.id, tsSecs: null)) return;

    final inviter = _nameFor(welcome.inviterNpub);
    final circleName = BookGroupNaming.matches(welcome.groupName)
        ? BookGroupNaming.titleOf(welcome.groupName)
        : welcome.groupName;
    await _show(
      id: welcome.id,
      title: 'New circle',
      body: 'You have been added to "$circleName" by $inviter',
      channel: ZapbookNotificationChannel.circles,
      tsSecs: null,
    );
  }

  Future<void> _onZap(ZapSatsEarningsRecord record) async {
    if (!_shouldNotify(id: record.id, tsSecs: record.timestamp)) return;

    var sender = 'someone';
    try {
      sender = _nameFor(Nip19.encodePubKey(record.senderNpub));
    } on Object catch (_) {}

    await _show(
      id: record.id,
      title: 'Sats earned',
      body: '⚡ You got zapped ${record.sats} sats from $sender',
      channel: ZapbookNotificationChannel.sats,
      tsSecs: record.timestamp,
    );
  }

  bool _shouldNotify({required String id, required int? tsSecs}) {
    if (!isEnabled) return false;
    if (_isForeground) return false;
    if (_seenIds.contains(id)) return false;
    if (tsSecs != null && tsSecs <= _cutoffSecs) return false;
    return true;
  }

  Future<void> _show({
    required String id,
    required String title,
    required String body,
    required ZapbookNotificationChannel channel,
    required int? tsSecs,
  }) async {
    _seenIds.add(id);
    if (_seenIds.length > 2000) _seenIds.clear();
    if (tsSecs != null && tsSecs > _watermark) {
      await _setWatermark(tsSecs);
    }
    await _notifications.show(
      id: id.hashCode & 0x7fffffff,
      title: title,
      body: body,
      channel: channel,
      payload: channel.id,
    );
    _log.info('Notified [$channel] $title');
  }

  bool get _isForeground =>
      SchedulerBinding.instance.lifecycleState == AppLifecycleState.resumed;

  String _nameFor(String npub) => _contacts.contactFor(npub).label;

  int get _watermark => _prefs?.getInt(_watermarkPrefKey) ?? 0;

  Future<void> _setWatermark(int secs) async {
    await _prefs?.setInt(_watermarkPrefKey, secs);
  }

  String _satsSuffix(int? sats) =>
      sats == null || sats <= 0 ? '' : ' $sats sats';

  int _nowSecs() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

  @disposeMethod
  void dispose() {
    for (final sub in _subs) {
      unawaited(sub.cancel());
    }
    _subs.clear();
  }
}
