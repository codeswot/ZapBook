import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;

enum ZapbookNotificationChannel {
  cheers(
    'zapbook_cheers',
    'Cheers & milestones',
    'Circle activity from friends',
  ),
  circles('zapbook_circles', 'Circle invites', 'New circles you are added to'),
  sats('zapbook_sats', 'Sats earned', 'Zaps you receive');

  const ZapbookNotificationChannel(this.id, this.title, this.description);

  final String id;
  final String title;
  final String description;
}

@lazySingleton
class LocalNotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  final _log = logging.Logger('LocalNotificationService');
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      iOS: DarwinInitializationSettings(),
    );
    try {
      await _plugin.initialize(settings: settings);
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        for (final channel in ZapbookNotificationChannel.values) {
          await android.createNotificationChannel(
            AndroidNotificationChannel(
              channel.id,
              channel.title,
              description: channel.description,
              importance: Importance.high,
            ),
          );
        }
      }
      _initialized = true;
    } on Object catch (error, stack) {
      _log.warning('init failed', error, stack);
    }
  }

  Future<bool> requestPermission() async {
    await init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return false;
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    required ZapbookNotificationChannel channel,
    String? payload,
  }) async {
    await init();
    if (!_initialized) return;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.title,
            channelDescription: channel.description,
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.social,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: payload,
      );
    } on Object catch (error, stack) {
      _log.warning('show failed', error, stack);
    }
  }
}
