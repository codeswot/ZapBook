import 'package:equatable/equatable.dart';

import 'package:zapbook/features/book_ingestion/presentation/widgets/reader/reading_style.dart';

class ReaderSettingsState extends Equatable {
  const ReaderSettingsState({this.font = ReaderFont.sans});

  final ReaderFont font;

  ReaderSettingsState copyWith({ReaderFont? font}) =>
      ReaderSettingsState(font: font ?? this.font);

  @override
  List<Object?> get props => [font];
}
