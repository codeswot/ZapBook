import 'package:zapbook/core/domain/quiz_models.dart';

abstract class QuizRepository {
  Stream<QuizSet> get onQuizSurface;
  void submitQuiz(int milestoneIdx, List<int> answers, QuizSet set);
  void skipQuiz(int milestoneIdx);
  Future<void> saveQuizBank(String circleDirId, List<QuizSet> quizzes);
  Future<List<QuizSet>> loadQuizBank(String circleDirId);
}
