import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/core/data/infrastructure/quiz_service.dart';
import 'package:zapbook/core/domain/quiz_models.dart';

void main() {
  late QuizService service;

  setUp(() {
    service = QuizService();
  });

  group('QuizService', () {
    test('initial state', () {
      expect(service.poolSize, 0);
      expect(service.stashSize, 0);
      expect(service.aiAvailable, isFalse);
      expect(service.shouldGenerate, isFalse);
    });

    test('generate adds to pool if aiAvailable and generator set', () async {
      service.aiAvailable = true;
      service.setGenerator(
        (idx, text) async => QuizSet(
          milestoneIdx: idx,
          questions: [],
          textContent: text,
          wordStart: 0,
          wordEnd: 0,
        ),
      );

      await service.generate(milestoneIdx: 1, textContent: 'text');
      expect(service.poolSize, 1);
    });

    test('skipQuiz sets result to skipped', () {
      service.skipQuiz(1);
      final result = service.resultFor(1);
      expect(result?.status, QuizStatus.skipped);
    });

    test('clear resets state', () async {
      service.aiAvailable = true;
      service.setGenerator(
        (idx, text) async => QuizSet(
          milestoneIdx: idx,
          questions: [],
          textContent: text,
          wordStart: 0,
          wordEnd: 0,
        ),
      );
      await service.generate(milestoneIdx: 1, textContent: 'text');
      service.skipQuiz(1);
      service.stashMilestone(1, 100, 5, 'text');

      service.clear();
      expect(service.poolSize, 0);
      expect(service.stashSize, 0);
      expect(service.resultFor(1), isNull);
    });
  });
}
