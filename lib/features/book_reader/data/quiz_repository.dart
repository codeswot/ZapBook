import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart';
import 'package:logging/logging.dart' as logging;

import 'package:zapbook/core/data/cache/nostr_cache_store.dart';
import 'package:zapbook/core/services/nostr_service.dart';
import 'package:zapbook/core/domain/quiz_models.dart';

@lazySingleton
class QuizRepository {
  QuizRepository(this._ndk, this._cache);

  final Ndk _ndk;
  final NostrCacheStore _cache;
  final _log = logging.Logger('QuizRepository');

  static const _kind = 30078;

  Future<void> saveQuizBank(String bookId, List<QuizSet> quizzes) async {
    _log.info(
      'saveQuizBank: saving ${quizzes.length} quizzes for book $bookId',
    );
    for (final q in quizzes) {
      _log.info(
        '  Milestone ${q.milestoneIdx}: ${q.questions.length} questions',
      );
    }

    final pubkey = _ndk.accounts.getPublicKey();
    if (pubkey == null) return;

    final account = _ndk.accounts.getLoggedAccount();
    if (account == null) return;

    final plaintext = jsonEncode(quizzes.map(_quizToJson).toList());
    final encrypted = await account.signer.encryptNip44(
      plaintext: plaintext,
      recipientPubKey: pubkey,
    );
    if (encrypted == null) return;

    final event = Nip01Event(
      pubKey: pubkey,
      kind: _kind,
      tags: [
        ['d', 'quizbank_$bookId'],
      ],
      content: encrypted,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    _ndk.broadcast.broadcast(
      nostrEvent: event,
      specificRelays: NostrService.broadcastRelays,
    );
  }

  Future<List<QuizSet>> loadQuizBank(String bookId) async {
    final pubkey = _ndk.accounts.getPublicKey();
    if (pubkey == null) return const [];

    final events = _cache.loadEvents(pubKeys: [pubkey], kinds: [_kind]);

    final match = events.where((e) {
      final dTag = e.tags.where((t) => t.length >= 2 && t[0] == 'd');
      return dTag.isNotEmpty && dTag.first[1] == 'quizbank_$bookId';
    });

    if (match.isEmpty) {
      _log.info('loadQuizBank: no quiz bank found for book $bookId');
      return const [];
    }

    final account = _ndk.accounts.getLoggedAccount();
    if (account == null) return const [];

    try {
      final plaintext = await account.signer.decryptNip44(
        ciphertext: match.first.content,
        senderPubKey: pubkey,
      );
      if (plaintext == null) return const [];

      final list = jsonDecode(plaintext) as List<dynamic>;
      final result = list
          .map((e) => _quizFromJson(e as Map<String, dynamic>))
          .toList();
      _log.info(
        'loadQuizBank: loaded ${result.length} quizzes for book $bookId',
      );
      return result;
    } catch (e) {
      _log.warning('loadQuizBank failed: $e');
      return const [];
    }
  }

  Map<String, dynamic> _quizToJson(QuizSet quiz) => {
    'milestone_idx': quiz.milestoneIdx,
    'text_content': quiz.textContent,
    'word_start': quiz.wordStart,
    'word_end': quiz.wordEnd,
    'questions': quiz.questions
        .map(
          (q) => {
            'text': q.text,
            'options': q.options,
            'correct_index': q.correctIndex,
          },
        )
        .toList(),
  };

  QuizSet _quizFromJson(Map<String, dynamic> json) {
    final qs = json['questions'] as List<dynamic>;
    final questions = qs.map((q) {
      final map = q as Map<String, dynamic>;
      return QuizQuestion(
        text: map['text'] as String,
        options: (map['options'] as List<dynamic>)
            .map((e) => e as String)
            .toList(),
        correctIndex: map['correct_index'] as int,
      );
    }).toList();

    return QuizSet(
      milestoneIdx: json['milestone_idx'] as int,
      questions: questions,
      textContent: json['text_content'] as String,
      wordStart: json['word_start'] as int,
      wordEnd: json['word_end'] as int,
    );
  }
}
