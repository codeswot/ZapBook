part of 'reading_progress_cubit.dart';

class ReadingProgressState extends Equatable {
  const ReadingProgressState({
    this.fraction = 0,
    this.currentPage = 0,
    this.wordsRead = 0,
    this.bookCompleted = false,
  });

  final double fraction;
  final int currentPage;
  final int wordsRead;
  final bool bookCompleted;

  @override
  List<Object?> get props => [fraction, currentPage, wordsRead, bookCompleted];
}
