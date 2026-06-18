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
  static const _textScaleKey = 'reader_text_scale';

  static ReaderSettingsState _load(SharedPreferences prefs) =>
      ReaderSettingsState(
        font: ReaderFont.fromName(prefs.getString(_fontKey)),
        textScale: prefs.getDouble(_textScaleKey) ?? 1.0,
      );

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

  void setTextScale(double scale) {
    if (scale == state.textScale) return;
    emit(state.copyWith(textScale: scale));
    _prefs.setDouble(_textScaleKey, scale);
  }
}
