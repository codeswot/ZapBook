import 'dart:math';

import 'package:injectable/injectable.dart';

import 'package:zapbook/core/data/search/book_vector_index.dart';
import 'package:zapbook/core/domain/quiz_models.dart';

@lazySingleton
class RecognitionQuizBuilder {
  RecognitionQuizBuilder(this._vectors);

  final BookVectorIndex _vectors;

  static const _optionsPerQuestion = 4;
  static const _minWords = 6;
  static const _maxWords = 40;
  static const _trimWords = 28;

  Future<QuizSet?> build(
    String bookId,
    int milestoneIdx,
    String sectionText, {
    Random? random,
  }) async {
    final rng = random ?? Random();
    final sectionSentences = _qualitySentences(sectionText);
    if (sectionSentences.length < 2) return null;

    final sectionLower = sectionText.toLowerCase();
    final hits = await _vectors.search(sectionText, limit: 40, minScore: 0);

    final distractors = <String>[];
    final usedLower = <String>{};
    for (final hit in hits) {
      if (sectionLower.contains(hit.text.toLowerCase())) continue;
      for (final sentence in _qualitySentences(hit.text)) {
        final lower = sentence.toLowerCase();
        if (usedLower.contains(lower) || sectionLower.contains(lower)) continue;
        distractors.add(sentence);
        usedLower.add(lower);
        break;
      }
      if (distractors.length >= 12) break;
    }
    if (distractors.length < 3) return null;

    final sectionPool = [...sectionSentences]..shuffle(rng);
    final distractorPool = [...distractors]..shuffle(rng);

    final questions = <QuizQuestion>[];
    var sectionCursor = 0;
    var distractorCursor = 0;

    for (var q = 0; q < QuizQuestion.questionsPerSet; q++) {
      final oddOneOut = q.isOdd;
      if (oddOneOut) {
        if (sectionPool.length - sectionCursor < _optionsPerQuestion - 1 ||
            distractorCursor >= distractorPool.length) {
          break;
        }
        final corrects = sectionPool.sublist(
          sectionCursor,
          sectionCursor + _optionsPerQuestion - 1,
        );
        sectionCursor += _optionsPerQuestion - 1;
        final distractor = distractorPool[distractorCursor++];
        final options = [...corrects, distractor]..shuffle(rng);
        questions.add(
          QuizQuestion(
            text: 'Which of these did you NOT read in this section?',
            options: [for (final o in options) _trim(o)],
            correctIndex: options.indexOf(distractor),
          ),
        );
      } else {
        if (sectionCursor >= sectionPool.length ||
            distractorPool.length - distractorCursor <
                _optionsPerQuestion - 1) {
          break;
        }
        final correct = sectionPool[sectionCursor++];
        final ds = distractorPool.sublist(
          distractorCursor,
          distractorCursor + _optionsPerQuestion - 1,
        );
        distractorCursor += _optionsPerQuestion - 1;
        final options = [correct, ...ds]..shuffle(rng);
        questions.add(
          QuizQuestion(
            text: 'Which of these did you read in this section?',
            options: [for (final o in options) _trim(o)],
            correctIndex: options.indexOf(correct),
          ),
        );
      }
    }

    if (questions.isEmpty) return null;
    return QuizSet(
      milestoneIdx: milestoneIdx,
      questions: questions,
      textContent: sectionText,
      wordStart: 0,
      wordEnd: 0,
    );
  }

  List<String> _qualitySentences(String text) {
    final flattened = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    final seen = <String>{};
    final out = <String>[];
    for (final match in RegExp(r'[^.!?]+[.!?]+').allMatches(flattened)) {
      final sentence = match.group(0)!.trim();
      final words = sentence.split(' ');
      if (words.length < _minWords || words.length > _maxWords) continue;
      if (sentence == sentence.toUpperCase()) continue;
      final lower = sentence.toLowerCase();
      if (!seen.add(lower)) continue;
      out.add(sentence);
    }
    return out;
  }

  String _trim(String sentence) {
    final words = sentence.split(' ');
    if (words.length <= _trimWords) return sentence;
    return '${words.sublist(0, _trimWords).join(' ')}…';
  }
}
