import 'package:equatable/equatable.dart';

import 'package:zapbook/core/presentation/theme/reading_style.dart';

class ReaderSettingsState extends Equatable {
  const ReaderSettingsState({
    this.font = ReaderFont.sans,
    this.textScale = 1.0,
    this.scrollDirection = ReaderScrollDirection.vertical,
  });

  final ReaderFont font;
  final double textScale;
  final ReaderScrollDirection scrollDirection;

  ReaderSettingsState copyWith({
    ReaderFont? font,
    double? textScale,
    ReaderScrollDirection? scrollDirection,
  }) => ReaderSettingsState(
    font: font ?? this.font,
    textScale: textScale ?? this.textScale,
    scrollDirection: scrollDirection ?? this.scrollDirection,
  );

  @override
  List<Object?> get props => [font, textScale, scrollDirection];
}
