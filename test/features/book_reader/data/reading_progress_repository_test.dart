import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ndk/ndk.dart';
import 'package:reading_progress/reading_progress.dart';
import 'package:zapbook/core/data/cache/nostr_cache_store.dart';
import 'package:zapbook/features/book_reader/data/reading_progress_repository.dart';

class MockNdk extends Mock implements Ndk {}

class MockAccounts extends Mock implements Accounts {}

class MockBroadcast extends Mock implements Broadcast {}

class MockNostrCacheStore extends Mock implements NostrCacheStore {}

class MockAccount extends Mock implements Account {}

class MockEventSigner extends Mock implements EventSigner {}

class FakeNip01Event extends Fake implements Nip01Event {}

class FakeNdkBroadcastResponse extends Fake implements NdkBroadcastResponse {}

void main() {
  late ReadingProgressRepository repository;
  late MockNdk mockNdk;
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
    mockAccounts = MockAccounts();
    mockBroadcast = MockBroadcast();
    mockCache = MockNostrCacheStore();
    mockAccount = MockAccount();
    mockSigner = MockEventSigner();

    when(() => mockNdk.accounts).thenReturn(mockAccounts);
    when(() => mockNdk.broadcast).thenReturn(mockBroadcast);
    when(() => mockAccount.signer).thenReturn(mockSigner);

    repository = ReadingProgressRepository(mockNdk, mockCache);
  });

  test('saveSnapshot saves encrypted reading progress', () async {
    when(() => mockAccounts.getPublicKey()).thenReturn('pub1');
    when(() => mockAccounts.getLoggedAccount()).thenReturn(mockAccount);
    when(
      () => mockSigner.encryptNip44(
        plaintext: any(named: 'plaintext'),
        recipientPubKey: any(named: 'recipientPubKey'),
      ),
    ).thenAnswer((_) async => 'encrypted_state');
    when(
      () => mockSigner.sign(any()),
    ).thenAnswer((_) async => FakeNip01Event());
    when(() => mockCache.saveEvent(any())).thenReturn(null);
    when(
      () => mockBroadcast.broadcast(
        nostrEvent: any(named: 'nostrEvent'),
        specificRelays: any(named: 'specificRelays'),
      ),
    ).thenReturn(FakeNdkBroadcastResponse());

    final state = ReadingState(
      wpm: 250,
      completedPages: {1, 2},
      visitedPages: {1, 2, 3},
      partials: {
        3: const PagePartial(engagedMs: 100, scrollSamples: 2, skimSamples: 1),
      },
      wordsRead: 1000,
      pointsBanked: 5,
      milestonesReached: 1,
      sessionEngagedMs: 5000,
      currentPage: 3,
      bookCompleted: false,
      open: null,
    );

    await repository.saveSnapshot('book1', state, scrollOffset: 15.5);

    final captures = verify(() => mockCache.saveEvent(captureAny())).captured;
    expect(captures.length, 1);
    final event = captures.first as Nip01Event;
    expect(event.kind, 30078);
    expect(event.content, 'encrypted_state');
    expect(event.tags.first, ['d', 'book1']);
  });

  test('loadSnapshot loads and decrypts reading progress', () async {
    when(() => mockAccounts.getPublicKey()).thenReturn('pub1');
    when(() => mockAccounts.getLoggedAccount()).thenReturn(mockAccount);

    final stateJson = {
      'wpm': 250.0,
      'completed_pages': [1, 2],
      'visited_pages': [1, 2, 3],
      'partials': {
        '3': {'engaged_ms': 100, 'scroll_samples': 2, 'skim_samples': 1},
      },
      'words_read': 1000,
      'points_banked': 5,
      'milestones_reached': 1,
      'session_engaged_ms': 5000,
      'current_page': 3,
      'book_completed': false,
      '_scroll_offset': 15.5,
    };

    when(
      () => mockSigner.decryptNip44(
        ciphertext: any(named: 'ciphertext'),
        senderPubKey: any(named: 'senderPubKey'),
      ),
    ).thenAnswer((_) async => jsonEncode(stateJson));

    final event = Nip01Event(
      pubKey: 'pub1',
      kind: 30078,
      tags: [
        ['d', 'book1'],
      ],
      content: 'encrypted_state',
      createdAt: 0,
    );

    when(
      () => mockCache.loadEvents(pubKeys: ['pub1'], kinds: [30078]),
    ).thenReturn([event]);

    final result = await repository.loadSnapshot('book1');
    expect(result, isNotNull);
    expect(result!.scrollOffset, 15.5);
    expect(result.state.wpm, 250);
    expect(result.state.completedPages, {1, 2});
    expect(result.state.wordsRead, 1000);
  });
}
