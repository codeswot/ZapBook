import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zapbook/features/book_reader/presentation/bloc/reader_settings/reader_settings_state.dart';
import 'package:zapbook/theme/reading_style.dart';

@LazySingleton()
class ReaderSettingsCubit extends Cubit<ReaderSettingsState> {
  ReaderSettingsCubit(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static const _fontKey = 'reader_font';

  static ReaderSettingsState _load(SharedPreferences prefs) =>
      ReaderSettingsState(font: ReaderFont.fromName(prefs.getString(_fontKey)));

  void cycleFont() {
    final next =
        ReaderFont.values[(state.font.index + 1) % ReaderFont.values.length];
    setFont(next);
  }

  void setFont(ReaderFont font) {
    if (font == state.font) return;
    emit(state.copyWith(font: font));
    _prefs.setString(_fontKey, font.name);
  }
}
