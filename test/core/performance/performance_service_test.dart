import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zapbook/core/performance/performance_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<PerformanceService> build([Map<String, Object> seed = const {}]) async {
    SharedPreferences.setMockInitialValues(seed);
    final prefs = await SharedPreferences.getInstance();
    return PerformanceService(prefs);
  }

  group('PerfMode.fromName', () {
    test('falls back to auto for null or unknown', () {
      expect(PerfMode.fromName(null), PerfMode.auto);
      expect(PerfMode.fromName('garbage'), PerfMode.auto);
    });

    test('parses known names', () {
      expect(PerfMode.fromName('on'), PerfMode.on);
      expect(PerfMode.fromName('off'), PerfMode.off);
      expect(PerfMode.fromName('auto'), PerfMode.auto);
    });
  });

  group('PerformanceService', () {
    test('defaults to auto with effects on when device is not legacy', () async {
      final service = await build();
      expect(service.mode, PerfMode.auto);
      expect(service.reduceEffects, isFalse);
    });

    test('setMode on forces reduced effects regardless of device', () async {
      final service = await build();
      await service.setMode(PerfMode.on);
      expect(service.mode, PerfMode.on);
      expect(service.reduceEffects, isTrue);
    });

    test('setMode off disables reduced effects', () async {
      final service = await build({'perf_mode': 'on'});
      await service.setMode(PerfMode.off);
      expect(service.reduceEffects, isFalse);
    });

    test('persists the chosen mode', () async {
      final service = await build();
      await service.setMode(PerfMode.on);

      final reloaded = await build({'perf_mode': 'on'});
      expect(reloaded.mode, PerfMode.on);
    });

    test('listenable reflects the latest reduceEffects value', () async {
      final service = await build();
      expect(service.reduceEffectsListenable.value, isFalse);
      await service.setMode(PerfMode.on);
      expect(service.reduceEffectsListenable.value, isTrue);
    });
  });
}
