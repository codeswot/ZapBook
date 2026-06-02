import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@LazySingleton()
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static const _key = 'app_theme_dark';

  static ThemeMode _load(SharedPreferences prefs) {
    final isDark = prefs.getBool(_key);
    if (isDark == null) {
      return ThemeMode.system;
    }
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  bool get isDark =>
      state == ThemeMode.dark ||
      (state == ThemeMode.system &&
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark);

  void toggle() {
    final next = isDark ? ThemeMode.light : ThemeMode.dark;
    emit(next);
    _prefs.setBool(_key, next == ThemeMode.dark);
  }
}
