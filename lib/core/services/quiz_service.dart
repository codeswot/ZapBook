import 'dart:async';

import 'package:injectable/injectable.dart';

import 'package:zapbook/core/domain/quiz_models.dart';

typedef QuizGenerator =
    Future<QuizSet?> Function(int milestoneIdx, String textContent);

@lazySingleton
class QuizService {
  static const quizPoolMin = 10;
  static const quizPoolGenerateTrigger = 5;
  static const quizPoolMax = 20;
  static const stashMax = 3;
  static const naturalPauseSeconds = 30;
  static const calibrationUnits = 3;

  final _pool = <QuizSet>[];
  final _stash = <QuizStashEntry>[];
  final _results = <int, QuizResult>{};
  QuizGenerator? _generator;

  bool aiAvailable = false;

  final _onSurface = StreamController<QuizSet>.broadcast();
  Stream<QuizSet> get onSurface => _onSurface.stream;

  final _onCompleted = StreamController<QuizResult>.broadcast();
  Stream<QuizResult> get onCompleted => _onCompleted.stream;

  int get poolSize => _pool.length;
  int get stashSize => _stash.length;
  bool get shouldGenerate =>
      aiAvailable && _pool.length < quizPoolGenerateTrigger;

  void setGenerator(QuizGenerator generator) {
    _generator = generator;
  }

  Future<void> generate({
    required int milestoneIdx,
    required String textContent,
  }) async {
    if (!aiAvailable || _generator == null) return;
    if (_pool.length >= quizPoolMax) return;
    final set = await _generator!(milestoneIdx, textContent);
    if (set != null) {
      _pool.add(set);
    }
  }

  QuizOutlook outlookForMilestone(int pointsBanked) {
    if (!aiAvailable) return QuizOutlook.unavailable;
    if (pointsBanked < calibrationUnits) return QuizOutlook.unavailable;
    return QuizOutlook.pending;
  }

  void stashMilestone(
    int milestoneIdx,
    int wordsRead,
    int pointsBanked,
    String textContent,
  ) {
    final outlook = outlookForMilestone(pointsBanked);
    _stash.add(
      QuizStashEntry(
        milestoneIdx: milestoneIdx,
        wordsRead: wordsRead,
        quizOutlook: outlook,
        textContent: textContent,
      ),
    );
    if (_stash.length >= stashMax) {
      _surfaceNext();
    }
  }

  void onPause() {
    _surfaceNext();
  }

  void checkIn() {
    _surfaceNext();
  }

  Future<void> _surfaceNext() async {
    if (_stash.isEmpty || !aiAvailable) return;
    final entry = _stash.removeAt(0);
    if (entry.quizOutlook == QuizOutlook.unavailable) return;

    var set = _pool
        .where((s) => s.milestoneIdx == entry.milestoneIdx)
        .firstOrNull;
    if (set == null) {
      set = await _generator?.call(entry.milestoneIdx, entry.textContent);
      if (set != null) {
        _pool.add(set);
      }
    }
    if (set != null) {
      _pool.remove(set);
      _onSurface.add(set);
    }
  }

  void skipQuiz(int milestoneIdx) {
    _results[milestoneIdx] = QuizResult(
      milestoneIdx: milestoneIdx,
      status: QuizStatus.skipped,
    );
  }

  void submitQuiz(int milestoneIdx, List<int> answers, QuizSet set) {
    var correct = 0;
    for (var i = 0; i < answers.length && i < set.questions.length; i++) {
      if (answers[i] == set.questions[i].correctIndex) correct++;
    }
    final score = set.questions.isEmpty ? 0.0 : correct / set.questions.length;
    final result = QuizResult(
      milestoneIdx: milestoneIdx,
      status: QuizStatus.completed,
      score: score,
    );
    _results[milestoneIdx] = result;
    _onCompleted.add(result);
  }

  QuizResult? resultFor(int milestoneIdx) => _results[milestoneIdx];

  QuizSet? pendingSet(int milestoneIdx) =>
      _pool.where((s) => s.milestoneIdx == milestoneIdx).firstOrNull;

  void clear() {
    _pool.clear();
    _stash.clear();
    _results.clear();
  }
}
