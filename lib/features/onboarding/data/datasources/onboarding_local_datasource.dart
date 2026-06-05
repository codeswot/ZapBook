import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@lazySingleton
class OnboardingLocalDataSource {
  const OnboardingLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const String _completeKey = 'onboarding_complete';

  bool isComplete() => _prefs.getBool(_completeKey) ?? false;

  Future<void> setComplete() => _prefs.setBool(_completeKey, true);
}
