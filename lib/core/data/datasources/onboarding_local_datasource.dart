import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@lazySingleton
class OnboardingLocalDataSource {
  const OnboardingLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const String _completeKey = 'onboarding_complete';
  static const String _circlePromptKey = 'circle_prompt_shown';

  bool isComplete() => _prefs.getBool(_completeKey) ?? false;

  Future<void> setComplete() => _prefs.setBool(_completeKey, true);

  Future<void> clear() => _prefs.remove(_completeKey);

  bool circlePromptShown() => _prefs.getBool(_circlePromptKey) ?? false;

  Future<void> setCirclePromptShown() => _prefs.setBool(_circlePromptKey, true);
}
