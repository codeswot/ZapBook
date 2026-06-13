import 'package:equatable/equatable.dart';

enum QuizOutlook { pending, unavailable }

enum QuizStatus { pending, completed, skipped }

class QuizQuestion extends Equatable {
  const QuizQuestion({
    required this.text,
    required this.options,
    required this.correctIndex,
  });

  final String text;
  final List<String> options;
  final int correctIndex;

  static const minOptions = 3;
  static const maxOptions = 5;
  static const questionsPerSet = 3;

  @override
  List<Object?> get props => [text, options, correctIndex];
}

class QuizSet extends Equatable {
  const QuizSet({
    required this.milestoneIdx,
    required this.questions,
    required this.textContent,
    required this.wordStart,
    required this.wordEnd,
  });

  final int milestoneIdx;
  final List<QuizQuestion> questions;
  final String textContent;
  final int wordStart;
  final int wordEnd;

  @override
  List<Object?> get props => [
    milestoneIdx,
    questions,
    textContent,
    wordStart,
    wordEnd,
  ];
}

class QuizStashEntry extends Equatable {
  const QuizStashEntry({
    required this.milestoneIdx,
    required this.wordsRead,
    required this.quizOutlook,
    required this.textContent,
  });

  final int milestoneIdx;
  final int wordsRead;
  final QuizOutlook quizOutlook;
  final String textContent;

  @override
  List<Object?> get props => [
    milestoneIdx,
    wordsRead,
    quizOutlook,
    textContent,
  ];
}

class QuizResult extends Equatable {
  const QuizResult({
    required this.milestoneIdx,
    required this.status,
    this.score,
  });

  final int milestoneIdx;
  final QuizStatus status;
  final double? score;

  @override
  List<Object?> get props => [milestoneIdx, status, score];
}
