import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@lazySingleton
class OnboardingLocalDataSource {
  const OnboardingLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const String _completeKey = 'onboarding_complete';
  static const String _lightningKey = 'onboarding_lightning_address';

  bool isComplete() => _prefs.getBool(_completeKey) ?? false;

  Future<void> setComplete() => _prefs.setBool(_completeKey, true);

  Future<void> saveLightningAddress(String address) =>
      _prefs.setString(_lightningKey, address);

  String? getLightningAddress() => _prefs.getString(_lightningKey);
}
