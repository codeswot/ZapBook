import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:logging/logging.dart' as logging;

import 'package:zapbook/core/services/ai_model_service.dart';
import 'package:zapbook/core/services/quiz_service.dart';
import 'package:zapbook/features/book_reader/data/quiz_repository.dart';
import 'package:zapbook/core/domain/quiz_models.dart';
import 'package:zapbook/zbf/zbf.dart';
import 'package:zapbook/features/book_reader/data/book_density_mapper.dart';

@lazySingleton
class AiService {
  AiService(this._aiModelService, this._quizRepository, this._quizService);

  final AiModelService _aiModelService;
  final QuizRepository _quizRepository;
  final QuizService _quizService;
  final _log = logging.Logger('AiService');
  StreamSubscription<AiModelState>? _subscription;
  bool _initialized = false;
  String? _modelPath;
  String? _activeBookId;
  ZbfBookHandle? _activeBookHandle;
  int? _activeMilestone;

  void init() {
    _subscription = _aiModelService.aiState.listen((state) {
      if (state.status == AiModelStatus.ready) {
        _loadModel();
      } else {
        _quizService.aiAvailable = false;
      }
    });

    if (_aiModelService.currentState.status == AiModelStatus.ready) {
      _loadModel();
    }
  }

  Future<void> _loadModel() async {
    if (_initialized) return;
    try {
      final File modelFile = await _aiModelService.model;
      _modelPath = modelFile.path;
      await FlutterGemma.installModel(
        modelType: ModelType.gemma4,
      ).fromFile(_modelPath!).install();
      _quizService.aiAvailable = true;
      _quizService.setGenerator(generateSingleQuiz);
      _initialized = true;

      final bookId = _activeBookId;
      final handle = _activeBookHandle;
      final milestone = _activeMilestone;
      if (bookId != null && handle != null && milestone != null) {
        unawaited(
          prePrepareQuizzes(
            bookId: bookId,
            handle: handle,
            currentMilestone: milestone,
          ),
        );
      }
    } catch (_) {}
  }

  static int _wordsPerMilestone(int totalWords) {
    if (totalWords >= 900) return 900;
    return (totalWords / 3).ceil().clamp(1, 300);
  }

  Future<QuizSet?> generateSingleQuiz(
    int milestoneIdx,
    String textContent,
  ) async {
    if (!_initialized || _modelPath == null) {
      return null;
    }
    final handle = _activeBookHandle;
    final totalWords = handle != null
        ? bookDensityFromHandle(handle).totalWords
        : 900;
    var text = textContent;
    text = text.replaceAll(RegExp(r'\.{2,}'), ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    final words = text.split(' ');
    if (words.length > 150) {
      text = words.take(150).join(' ');
    }
    final prompt = _buildQuizPrompt(milestoneIdx, text);
    final responseText = await _generateText(prompt);
    if (responseText == null) {
      return null;
    }
    final parsed = _parseQuizResponse(
      responseText,
      milestoneIdx,
      text,
      totalWords,
    );
    return parsed;
  }

  Future<void> prePrepareQuizzes({
    required String bookId,
    required ZbfBookHandle handle,
    required int currentMilestone,
  }) async {
    _activeBookId = bookId;
    _activeBookHandle = handle;
    _activeMilestone = currentMilestone;

    if (!_initialized || _modelPath == null) {
      return;
    }

    final existingQuizzes = await _quizRepository.loadQuizBank(bookId);
    final existingMap = {for (final q in existingQuizzes) q.milestoneIdx: q};

    final totalWords = bookDensityFromHandle(handle).totalWords;
    final milestoneSize = _wordsPerMilestone(totalWords);
    final totalMilestones = (totalWords / milestoneSize).ceil();

    final List<QuizSet> newQuizzes = List.from(existingQuizzes);
    final density = bookDensityFromHandle(handle);

    for (var i = 0; i < 6; i++) {
      final idx = currentMilestone + i;
      if (idx >= totalMilestones) {
        break;
      }

      if (existingMap.containsKey(idx)) {
        continue;
      }

      var text = extractMilestoneText(
        handle,
        density,
        idx,
        wordsPerMilestone: milestoneSize,
      );
      text = text.replaceAll(RegExp(r'\.{2,}'), ' ');
      text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (text.isEmpty) {
        continue;
      }
      if (_isTableOfContents(text)) {
        continue;
      }

      final words = text.split(' ');
      if (words.length > 150) {
        text = words.take(150).join(' ');
      }

      try {
        final mainGenerated = await generateSingleQuiz(idx, text);
        if (mainGenerated != null) {
          newQuizzes.add(mainGenerated);
          await _quizRepository.saveQuizBank(bookId, newQuizzes);
        } else {}
      } catch (e) {
        _log.warning('preparing quiz $e');
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<String?> _generateText(String prompt) async {
    InferenceModel? model;
    try {
      model = await FlutterGemma.getActiveModel(maxTokens: 2048);
      final session = await model.createSession(temperature: 0.2);
      try {
        await session.addQueryChunk(Message(text: prompt, isUser: true));
        final res = await session.getResponse();
        return res;
      } finally {
        await session.close();
      }
    } catch (e) {
      if (model != null) {
        try {
          await model.close();
        } catch (closeErr) {
          _log.warning('_generateText quiz $e');
        }
      }
      return null;
    }
  }

  String _buildQuizPrompt(int milestoneIdx, String textContent) {
    return '''
Based on the text below, generate exactly 3 multiple-choice questions. Each question must have exactly 4 options. Return strictly in this JSON format:
{
  "milestoneIdx": $milestoneIdx,
  "questions": [
    {
      "text": "Question about a fact in the text?",
      "options": ["Correct option", "Distractor 1", "Distractor 2", "Distractor 3"],
      "correctIndex": 0
    }
  ]
}

Text:
$textContent
''';
  }

  static QuizSet? _parseQuizResponse(
    String responseText,
    int milestoneIdx,
    String textContent,
    int totalWords,
  ) {
    final milestoneSize = _wordsPerMilestone(totalWords);
    try {
      final startIdx = responseText.indexOf('{');
      final endIdx = responseText.lastIndexOf('}');
      if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
        final jsonSub = responseText.substring(startIdx, endIdx + 1);
        final decoded = jsonDecode(jsonSub) as Map<String, dynamic>;
        final questionsRaw = decoded['questions'] as List<dynamic>;
        final List<QuizQuestion> questions = [];
        for (final q in questionsRaw) {
          final qMap = q as Map<String, dynamic>;
          final String text = qMap['text'] ?? qMap['question'] ?? '';
          final List<String> options = (qMap['options'] as List<dynamic>)
              .map((e) => e.toString())
              .toList();
          final int correctIndex =
              (qMap['correctIndex'] ?? qMap['correct_index'] ?? 0) as int;
          if (text.isNotEmpty && options.length >= 3) {
            questions.add(
              QuizQuestion(
                text: text,
                options: options,
                correctIndex: correctIndex,
              ),
            );
          }
        }
        if (questions.isNotEmpty) {
          return QuizSet(
            milestoneIdx: milestoneIdx,
            questions: questions,
            textContent: textContent,
            wordStart: milestoneIdx * milestoneSize,
            wordEnd: (milestoneIdx + 1) * milestoneSize,
          );
        }
      }
    } catch (_) {}

    try {
      final List<QuizQuestion> questions = [];
      final questionBlocks = responseText.split(
        RegExp(r'(?:question|{"text"|text)\s*:'),
      );
      for (final block in questionBlocks) {
        if (block.trim().isEmpty) continue;
        final textMatch = RegExp(r'^[^"]*"([^"]+)"').firstMatch(block);
        if (textMatch == null) continue;
        final text = textMatch.group(1)!;

        final optionsMatch = RegExp(
          r'options\s*:\s*\[([^\]]+)\]',
        ).firstMatch(block);
        if (optionsMatch == null) continue;
        final optionsStr = optionsMatch.group(1)!;
        final options = RegExp(
          r'"([^"]+)"',
        ).allMatches(optionsStr).map((m) => m.group(1)!).toList();

        final correctMatch = RegExp(
          r'correctIndex\s*:\s*(\d+)',
        ).firstMatch(block);
        final correctIndex = correctMatch != null
            ? int.parse(correctMatch.group(1)!)
            : 0;

        if (text.isNotEmpty && options.length >= 3) {
          questions.add(
            QuizQuestion(
              text: text,
              options: options,
              correctIndex: correctIndex,
            ),
          );
        }
      }
      if (questions.isNotEmpty) {
        return QuizSet(
          milestoneIdx: milestoneIdx,
          questions: questions,
          textContent: textContent,
          wordStart: milestoneIdx * milestoneSize,
          wordEnd: (milestoneIdx + 1) * milestoneSize,
        );
      }
    } catch (_) {}

    return null;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
  }

  bool _isTableOfContents(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('table of contents') ||
        lower.contains('contents') ||
        lower.contains('index')) {
      return true;
    }
    final words = text.split(' ');
    if (words.length < 20) return true;
    var numberOrSingleCharCount = 0;
    for (final word in words) {
      if (RegExp(r'^\d+$').hasMatch(word) || word.length <= 1) {
        numberOrSingleCharCount++;
      }
    }
    if (numberOrSingleCharCount / words.length > 0.25) {
      return true;
    }
    return false;
  }
}
