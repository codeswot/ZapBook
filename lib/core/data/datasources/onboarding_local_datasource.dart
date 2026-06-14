import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zapbook/core/identity/active_account.dart';

class PendingProfile {
  const PendingProfile({this.displayName, this.lud16, this.picture});

  final String? displayName;
  final String? lud16;
  final String? picture;
}

@lazySingleton
class OnboardingLocalDataSource {
  const OnboardingLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const String _completeKey = 'onboarding_complete';
  static const String _pendingProfileKey = 'pending_profile_publish';

  static String get _circlePromptKey =>
      ActiveAccount.key('circle_prompt_shown');

  bool isComplete() => _prefs.getBool(_completeKey) ?? false;

  Future<void> setComplete() => _prefs.setBool(_completeKey, true);

  Future<void> clear() => _prefs.remove(_completeKey);

  bool circlePromptShown() => _prefs.getBool(_circlePromptKey) ?? false;

  Future<void> setCirclePromptShown() => _prefs.setBool(_circlePromptKey, true);

  Future<void> writePendingProfile({
    String? displayName,
    String? lud16,
    String? picture,
  }) => _prefs.setString(
    _pendingProfileKey,
    jsonEncode({
      'displayName': displayName,
      'lud16': lud16,
      'picture': picture,
    }),
  );

  PendingProfile? readPendingProfile() {
    final raw = _prefs.getString(_pendingProfileKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return PendingProfile(
        displayName: map['displayName'] as String?,
        lud16: map['lud16'] as String?,
        picture: map['picture'] as String?,
      );
    } on Object {
      return null;
    }
  }

  Future<void> clearPendingProfile() => _prefs.remove(_pendingProfileKey);
}
