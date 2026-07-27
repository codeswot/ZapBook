import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ndk/ndk.dart';
import 'package:zapbook/core/data/cache/nostr_cache_store.dart';
import 'package:zapbook/core/data/infrastructure/highlight_private_sync_service.dart';
import 'package:zapbook/features/book_reader/domain/entities/highlight.dart';

class MockNdk extends Mock implements Ndk {}

class MockAccounts extends Mock implements Accounts {}

class MockBroadcast extends Mock implements Broadcast {}

class MockNostrCacheStore extends Mock implements NostrCacheStore {}

class MockAccount extends Mock implements Account {}

class MockEventSigner extends Mock implements EventSigner {}

class FakeNip01Event extends Fake implements Nip01Event {}

class FakeNdkBroadcastResponse extends Fake implements NdkBroadcastResponse {}

void main() {
  late HighlightPrivateSyncService service;
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

    service = HighlightPrivateSyncService(mockNdk, mockCache);
  });

  final highlight = Highlight(
    id: 'h1',
    bookId: 'book1',
    ownerNpub: 'npub1owner',
    visibility: HighlightVisibility.private,
    pageNumber: 3,
    spans: const [
      HighlightSpan(originalBlockIndex: 0, startOffset: 0, endOffset: 5),
    ],
    quoteSnapshot: 'quote',
    createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(1000),
  );

  test('publish encrypts to own pubkey and broadcasts kind 30078', () async {
    when(() => mockAccounts.getPublicKey()).thenReturn('pub1');
    when(() => mockAccounts.getLoggedAccount()).thenReturn(mockAccount);
    when(
      () => mockSigner.encryptNip44(
        plaintext: any(named: 'plaintext'),
        recipientPubKey: any(named: 'recipientPubKey'),
      ),
    ).thenAnswer((_) async => 'encrypted_highlight');
    when(
      () => mockBroadcast.broadcast(
        nostrEvent: any(named: 'nostrEvent'),
        specificRelays: any(named: 'specificRelays'),
      ),
    ).thenReturn(FakeNdkBroadcastResponse());

    await service.publish(highlight);

    final recipientPubKey = verify(
      () => mockSigner.encryptNip44(
        plaintext: any(named: 'plaintext'),
        recipientPubKey: captureAny(named: 'recipientPubKey'),
      ),
    ).captured.single;
    expect(recipientPubKey, 'pub1');

    final captures = verify(
      () => mockBroadcast.broadcast(
        nostrEvent: captureAny(named: 'nostrEvent'),
        specificRelays: any(named: 'specificRelays'),
      ),
    ).captured;
    final event = captures.first as Nip01Event;
    expect(event.kind, 30078);
    expect(event.content, 'encrypted_highlight');
    expect(event.tags.first, ['d', 'zbhighlight_h1']);
  });

  test('loadAll decrypts and parses events tagged for highlights', () async {
    when(() => mockAccounts.getPublicKey()).thenReturn('pub1');
    when(() => mockAccounts.getLoggedAccount()).thenReturn(mockAccount);

    final plaintext = jsonEncode({
      'v': 1,
      'id': 'h1',
      'bookId': 'book1',
      'ownerNpub': 'npub1owner',
      'visibility': 'private',
      'groupId': null,
      'pageNumber': 3,
      'spans': [
        {'originalBlockIndex': 0, 'startOffset': 0, 'endOffset': 5},
      ],
      'quoteSnapshot': 'quote',
      'note': null,
      'createdAt': 1000,
      'updatedAt': 1000,
      'deleted': false,
    });

    when(
      () => mockSigner.decryptNip44(
        ciphertext: any(named: 'ciphertext'),
        senderPubKey: any(named: 'senderPubKey'),
      ),
    ).thenAnswer((_) async => plaintext);

    final event = Nip01Event(
      pubKey: 'pub1',
      kind: 30078,
      tags: [
        ['d', 'zbhighlight_h1'],
      ],
      content: 'encrypted',
      createdAt: 0,
    );

    when(
      () => mockCache.loadEvents(pubKeys: ['pub1'], kinds: [30078]),
    ).thenReturn([event]);

    final result = await service.loadAll();

    expect(result.length, 1);
    expect(result.first.id, 'h1');
    expect(result.first.quoteSnapshot, 'quote');
    expect(result.first.spans.single.startOffset, 0);
  });

  test('loadAll ignores events with unrelated d-tags', () async {
    when(() => mockAccounts.getPublicKey()).thenReturn('pub1');
    when(() => mockAccounts.getLoggedAccount()).thenReturn(mockAccount);

    final event = Nip01Event(
      pubKey: 'pub1',
      kind: 30078,
      tags: [
        ['d', 'quizbank_book1'],
      ],
      content: 'encrypted',
      createdAt: 0,
    );

    when(
      () => mockCache.loadEvents(pubKeys: ['pub1'], kinds: [30078]),
    ).thenReturn([event]);

    final result = await service.loadAll();

    expect(result, isEmpty);
  });
}
