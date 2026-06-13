import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zapbook/core/domain/quiz_models.dart';
import 'package:zapbook/core/services/quiz_service.dart';

enum QuizScreenState { idle, active, reveal, done }

class QuizCubitState {
  const QuizCubitState({
    this.screen = QuizScreenState.idle,
    this.set,
    this.currentIndex = 0,
    this.answers = const [],
    this.score,
  });

  final QuizScreenState screen;
  final QuizSet? set;
  final int currentIndex;
  final List<int> answers;
  final double? score;
}

class QuizCubit extends Cubit<QuizCubitState> {
  QuizCubit(this._quizService) : super(const QuizCubitState());

  final QuizService _quizService;
  StreamSubscription<QuizSet>? _sub;

  void start() {
    _sub = _quizService.onSurface.listen((set) {
      if (state.screen == QuizScreenState.idle) {
        emit(QuizCubitState(screen: QuizScreenState.active, set: set));
      }
    });
  }

  void answer(int selectedIndex) {
    final answers = [...state.answers, selectedIndex];
    final nextIndex = state.currentIndex + 1;
    final set = state.set;
    if (set == null) return;

    if (nextIndex >= set.questions.length) {
      final correct = answers
          .asMap()
          .entries
          .where((e) => e.value == set.questions[e.key].correctIndex)
          .length;
      final score = correct / set.questions.length;
      _quizService.submitQuiz(set.milestoneIdx, answers, set);
      emit(
        QuizCubitState(
          screen: QuizScreenState.reveal,
          set: set,
          currentIndex: nextIndex,
          answers: answers,
          score: score,
        ),
      );
    } else {
      emit(
        QuizCubitState(
          screen: QuizScreenState.active,
          set: set,
          currentIndex: nextIndex,
          answers: answers,
        ),
      );
    }
  }

  void skip() {
    final set = state.set;
    if (set != null) {
      _quizService.skipQuiz(set.milestoneIdx);
    }
    emit(const QuizCubitState(screen: QuizScreenState.done));
  }

  void dismiss() {
    emit(const QuizCubitState(screen: QuizScreenState.idle));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
