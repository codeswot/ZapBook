import 'package:zapbook/core/data/infrastructure/quiz_service.dart';
import 'package:zapbook/features/book_reader/data/repositories/quiz_repository_impl.dart';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ndk/ndk.dart';
import 'package:zapbook/core/data/cache/nostr_cache_store.dart';
import 'package:zapbook/core/domain/quiz_models.dart';

class MockNdk extends Mock implements Ndk {}

class MockQuizService extends Mock implements QuizService {}

class MockAccounts extends Mock implements Accounts {}

class MockBroadcast extends Mock implements Broadcast {}

class MockNostrCacheStore extends Mock implements NostrCacheStore {}

class MockAccount extends Mock implements Account {}

class MockEventSigner extends Mock implements EventSigner {}

class FakeNip01Event extends Fake implements Nip01Event {}

class FakeNdkBroadcastResponse extends Fake implements NdkBroadcastResponse {}

void main() {
  late QuizRepositoryImpl repository;
  late MockNdk mockNdk;
  late MockQuizService mockQuizService;
  late MockAccounts mockAccounts;
  late MockBroadcast mockBroadcast;
  late MockNostrCacheStore mockCache;
  late MockAccount mockAccount;
  late MockEventSigner mockSigner;

  setUpAll(() {
    registerFallbackValue(FakeNip01Event());
  });

  setUp(() {
    mockNdk = MockNdk();
    mockQuizService = MockQuizService();
    mockAccounts = MockAccounts();
    mockBroadcast = MockBroadcast();
    mockCache = MockNostrCacheStore();
    mockAccount = MockAccount();
    mockSigner = MockEventSigner();

    when(() => mockNdk.accounts).thenReturn(mockAccounts);
    when(() => mockNdk.broadcast).thenReturn(mockBroadcast);
    when(() => mockAccount.signer).thenReturn(mockSigner);

    repository = QuizRepositoryImpl(mockNdk, mockCache, mockQuizService);
  });

  test('saveQuizBank saves encrypted quizzes', () async {
    when(() => mockAccounts.getPublicKey()).thenReturn('pub1');
    when(() => mockAccounts.getLoggedAccount()).thenReturn(mockAccount);
    when(
      () => mockSigner.encryptNip44(
        plaintext: any(named: 'plaintext'),
        recipientPubKey: any(named: 'recipientPubKey'),
      ),
    ).thenAnswer((_) async => 'encrypted_quizzes');
    when(
      () => mockSigner.sign(any()),
    ).thenAnswer((_) async => FakeNip01Event());
    when(
      () => mockBroadcast.broadcast(
        nostrEvent: any(named: 'nostrEvent'),
        specificRelays: any(named: 'specificRelays'),
      ),
    ).thenReturn(FakeNdkBroadcastResponse());

    final quizzes = [
      QuizSet(
        milestoneIdx: 1,
        questions: [
          QuizQuestion(text: 'Q1', options: ['A', 'B'], correctIndex: 0),
        ],
        textContent: 'text',
        wordStart: 0,
        wordEnd: 4,
      ),
    ];

    await repository.saveQuizBank('book1', quizzes);

    final captures = verify(
      () => mockBroadcast.broadcast(
        nostrEvent: captureAny(named: 'nostrEvent'),
        specificRelays: any(named: 'specificRelays'),
      ),
    ).captured;
    expect(captures.length, 1);
    final event = captures.first as Nip01Event;
    expect(event.kind, 30078);
    expect(event.content, 'encrypted_quizzes');
    expect(event.tags.first, ['d', 'quizbank_book1']);
  });

  test('loadQuizBank loads and decrypts quizzes', () async {
    when(() => mockAccounts.getPublicKey()).thenReturn('pub1');
    when(() => mockAccounts.getLoggedAccount()).thenReturn(mockAccount);

    final quizJson = [
      {
        'milestone_idx': 1,
        'text_content': 'text',
        'word_start': 0,
        'word_end': 4,
        'questions': [
          {
            'text': 'Q1',
            'options': ['A', 'B'],
            'correct_index': 0,
          },
        ],
      },
    ];

    when(
      () => mockSigner.decryptNip44(
        ciphertext: any(named: 'ciphertext'),
        senderPubKey: any(named: 'senderPubKey'),
      ),
    ).thenAnswer((_) async => jsonEncode(quizJson));

    final event = Nip01Event(
      pubKey: 'pub1',
      kind: 30078,
      tags: [
        ['d', 'quizbank_book1'],
      ],
      content: 'encrypted_quizzes',
      createdAt: 0,
    );

    when(
      () => mockCache.loadEvents(pubKeys: ['pub1'], kinds: [30078]),
    ).thenReturn([event]);

    final result = await repository.loadQuizBank('book1');
    expect(result.length, 1);
    expect(result.first.milestoneIdx, 1);
    expect(result.first.textContent, 'text');
    expect(result.first.questions.length, 1);
    expect(result.first.questions.first.text, 'Q1');
  });
}
