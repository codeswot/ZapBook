import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@lazySingleton
class ZapSupportService {
  ZapSupportService(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'zapbook_support_percent';
  static const defaultPercent = 5;

  int get percent => _prefs.getInt(_key) ?? defaultPercent;

  Future<void> setPercent(int value) =>
      _prefs.setInt(_key, value.clamp(0, 100));

  bool get isEnabled => percent > 0;

  static const options = [0, 3, 5, 10, 15, 20, 50, 100];
}
