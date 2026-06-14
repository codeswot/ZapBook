import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PerfMode {
  auto,
  on,
  off;

  static PerfMode fromName(String? name) => PerfMode.values.firstWhere(
    (mode) => mode.name == name,
    orElse: () => PerfMode.auto,
  );
}

@singleton
class PerformanceService {
  PerformanceService(this._prefs);

  final SharedPreferences _prefs;

  static const _modeKey = 'perf_mode';
  static const _legacyAndroidSdk = 29;

  final ValueNotifier<bool> _reduceEffects = ValueNotifier<bool>(false);

  ValueListenable<bool> get reduceEffectsListenable => _reduceEffects;

  bool get reduceEffects => _reduceEffects.value;

  bool _deviceIsLegacy = false;

  bool get deviceIsLegacy => _deviceIsLegacy;

  PerfMode get mode => PerfMode.fromName(_prefs.getString(_modeKey));

  Future<void> init() async {
    _deviceIsLegacy = await _detectLegacyDevice();
    _recompute();
  }

  Future<void> setMode(PerfMode value) async {
    await _prefs.setString(_modeKey, value.name);
    _recompute();
  }

  void _recompute() {
    _reduceEffects.value = switch (mode) {
      PerfMode.on => true,
      PerfMode.off => false,
      PerfMode.auto => _deviceIsLegacy,
    };
  }

  Future<bool> _detectLegacyDevice() async {
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final android = await info.androidInfo;
        return android.isLowRamDevice ||
            android.version.sdkInt <= _legacyAndroidSdk;
      }
      return false;
    } on Exception {
      return false;
    }
  }
}
