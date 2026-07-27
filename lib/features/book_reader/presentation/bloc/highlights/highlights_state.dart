import 'package:zapbook/features/book_reader/domain/entities/highlight.dart';

sealed class HighlightsState {
  const HighlightsState();
}

class HighlightsLoading extends HighlightsState {
  const HighlightsLoading();
}

class HighlightsLoaded extends HighlightsState {
  const HighlightsLoaded(this.highlights);
  final List<Highlight> highlights;
}
