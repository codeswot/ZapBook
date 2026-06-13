class MilestonePayload {
  const MilestonePayload({
    required this.bookId,
    required this.milestoneIdx,
    required this.currentWordCount,
    required this.totalWordCount,
    required this.progressPct,
    required this.currentPage,
    required this.sessionReadingSeconds,
    required this.quizOutlook,
    required this.reachedAt,
  });

  final String bookId;
  final int milestoneIdx;
  final int currentWordCount;
  final int totalWordCount;
  final double progressPct;
  final int currentPage;
  final int sessionReadingSeconds;
  final String quizOutlook;
  final String reachedAt;

  static const messageType = 'zapbook.book.milestone';

  Map<String, dynamic> toJson() => {
    'type': messageType,
    'book_id': bookId,
    'milestone_idx': milestoneIdx,
    'current_word_count': currentWordCount,
    'total_word_count': totalWordCount,
    'progress_pct': progressPct,
    'current_page': currentPage,
    'session_reading_seconds': sessionReadingSeconds,
    'quiz_outlook': quizOutlook,
    'reached_at': reachedAt,
  };
}
