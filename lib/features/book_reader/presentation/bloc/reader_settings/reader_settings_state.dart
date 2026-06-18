import 'package:equatable/equatable.dart';

import 'package:zapbook/theme/reading_style.dart';

class ReaderSettingsState extends Equatable {
  const ReaderSettingsState({
    this.font = ReaderFont.sans,
    this.textScale = 1.0,
  });

  final ReaderFont font;
  final double textScale;

  ReaderSettingsState copyWith({ReaderFont? font, double? textScale}) =>
      ReaderSettingsState(
        font: font ?? this.font,
        textScale: textScale ?? this.textScale,
      );

  @override
  List<Object?> get props => [font, textScale];
}
