import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@LazySingleton()
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static const _key = 'app_theme_dark';

  static ThemeMode _load(SharedPreferences prefs) =>
      (prefs.getBool(_key) ?? false) ? ThemeMode.dark : ThemeMode.light;

  bool get isDark => state == ThemeMode.dark;

  void toggle() {
    final next = isDark ? ThemeMode.light : ThemeMode.dark;
    emit(next);
    _prefs.setBool(_key, next == ThemeMode.dark);
  }
}
