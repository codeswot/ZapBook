import 'dart:io';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;

@lazySingleton
class SyncServiceChannel {
  static const _channel = MethodChannel('zapbook/sync_service');
  final _log = logging.Logger('SyncServiceChannel');

  bool get _supported => Platform.isAndroid;

  Future<void> start() => _invoke('start');

  Future<void> stop() => _invoke('stop');

  Future<bool> isIgnoringBatteryOptimizations() async {
    if (!_supported) return true;
    try {
      final result = await _channel.invokeMethod<bool>(
        'isIgnoringBatteryOptimizations',
      );
      return result ?? false;
    } on PlatformException catch (error) {
      _log.warning('isIgnoringBatteryOptimizations failed', error);
      return false;
    }
  }

  Future<void> requestIgnoreBatteryOptimizations() =>
      _invoke('requestIgnoreBatteryOptimizations');

  Future<void> _invoke(String method) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>(method);
    } on PlatformException catch (error) {
      _log.warning('$method failed', error);
    }
  }
}
