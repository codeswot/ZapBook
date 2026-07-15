import 'package:injectable/injectable.dart';
import 'package:zapbook/core/domain/quiz_models.dart';
import 'package:zapbook/features/book_reader/domain/repositories/quiz_repository.dart';

@injectable
class WatchQuizSurfaceUseCase {
  const WatchQuizSurfaceUseCase(this._repository);

  final QuizRepository _repository;

  Stream<QuizSet> call() => _repository.onQuizSurface;
}

@injectable
class SubmitQuizUseCase {
  const SubmitQuizUseCase(this._repository);

  final QuizRepository _repository;

  void call(int milestoneIdx, List<int> answers, QuizSet set) =>
      _repository.submitQuiz(milestoneIdx, answers, set);
}

@injectable
class SkipQuizUseCase {
  const SkipQuizUseCase(this._repository);

  final QuizRepository _repository;

  void call(int milestoneIdx) => _repository.skipQuiz(milestoneIdx);
}
