import 'package:zapbook/features/book_reader/domain/entities/highlight.dart';

sealed class BookHighlightsState {
  const BookHighlightsState();
}

class BookHighlightsLoading extends BookHighlightsState {
  const BookHighlightsLoading();
}

class BookHighlightsLoaded extends BookHighlightsState {
  const BookHighlightsLoaded(this.highlights);
  final List<Highlight> highlights;
}
