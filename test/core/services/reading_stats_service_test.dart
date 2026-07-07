import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ndk/ndk.dart';
import 'package:zapbook/core/data/cache/nostr_cache_store.dart';
import 'package:zapbook/core/services/milestone_service.dart';
import 'package:zapbook/core/services/zap_earnings_service.dart';
import 'package:zapbook/core/services/reading_stats_service.dart';

class MockNdk extends Mock implements Ndk {}

class MockAccounts extends Mock implements Accounts {}

class MockBroadcast extends Mock implements Broadcast {}

class MockSigner extends Mock implements Bip340EventSigner {}

class MockNostrCacheStore extends Mock implements NostrCacheStore {}

class MockMilestoneService extends Mock implements MilestoneService {}

class MockZapEarningsService extends Mock implements ZapEarningsService {}

class FakeNip01Event extends Fake implements Nip01Event {}

class MockNdkBroadcastResponse extends Mock implements NdkBroadcastResponse {}

void main() {
  late MockNdk mockNdk;
  late MockAccounts mockAccounts;
  late MockBroadcast mockBroadcast;
  late MockSigner mockSigner;

  late MockNostrCacheStore mockCache;
  late MockMilestoneService mockMilestoneService;
  late MockZapEarningsService mockEarnings;
  late ReadingStatsService service;

  setUpAll(() {
    registerFallbackValue(FakeNip01Event());
  });

  setUp(() {
    mockNdk = MockNdk();
    mockAccounts = MockAccounts();
    mockBroadcast = MockBroadcast();
    mockSigner = MockSigner();

    when(() => mockNdk.accounts).thenReturn(mockAccounts);
    when(() => mockNdk.broadcast).thenReturn(mockBroadcast);

    mockCache = MockNostrCacheStore();
    mockMilestoneService = MockMilestoneService();
    mockEarnings = MockZapEarningsService();

    // Default earnings stubs
    when(() => mockEarnings.totalEarned).thenReturn(ValueNotifier<int>(100));
    when(() => mockEarnings.earnedForCircle(any())).thenReturn(50);
    when(() => mockEarnings.start()).thenAnswer((_) async {});

    // Default milestone stubs
    when(() => mockMilestoneService.completedBooksCount).thenReturn(5);
    when(() => mockMilestoneService.myMilestonesCount).thenReturn(10);
    when(() => mockMilestoneService.allMilestoneDates).thenReturn({});
    when(() => mockMilestoneService.syncAll()).thenAnswer((_) async {});

    service = ReadingStatsService(
      mockNdk,
      mockCache,
      mockMilestoneService,
      mockEarnings,
    );
  });

  String today() => DateTime.now().toUtc().toIso8601String().substring(0, 10);
  String yesterday() => DateTime.now()
      .toUtc()
      .subtract(const Duration(days: 1))
      .toIso8601String()
      .substring(0, 10);
  String dayBeforeYesterday() => DateTime.now()
      .toUtc()
      .subtract(const Duration(days: 2))
      .toIso8601String()
      .substring(0, 10);

  test('properties return values from dependencies', () {
    expect(service.booksRead, 5);
    expect(service.milestones, 10);
    expect(service.satsEarned, 100);
    expect(service.satsEarnedForCircle('test-circle'), 50);
    expect(service.satsEarnedListenable, isA<ValueNotifier<int>>());
  });

  test('syncBookStats delegates to MilestoneService', () async {
    await service.syncBookStats();
    verify(() => mockMilestoneService.syncAll()).called(1);
  });

  test('streak calculates correctly from milestone dates', () {
    expect(service.streak, 0);

    when(
      () => mockMilestoneService.allMilestoneDates,
    ).thenReturn({dayBeforeYesterday(), yesterday(), today()});

    expect(service.streak, 3);
  });

  test(
    'streak does not reset if today is missing but yesterday is present',
    () {
      when(
        () => mockMilestoneService.allMilestoneDates,
      ).thenReturn({dayBeforeYesterday(), yesterday()});

      expect(service.streak, 2);
    },
  );

  test('streak is 0 if last date is older than yesterday', () {
    when(
      () => mockMilestoneService.allMilestoneDates,
    ).thenReturn({dayBeforeYesterday()});

    expect(service.streak, 0);
  });

  test('load parses raw cache event and starts earnings', () async {
    when(() => mockAccounts.getPublicKey()).thenReturn('pubkey1');
    when(
      () => mockCache.loadEvents(pubKeys: ['pubkey1'], kinds: [30078]),
    ).thenReturn([
      Nip01Event(
        pubKey: 'pubkey1',
        kind: 30078,
        tags: [
          ['d', 'zapbook:stats:raw'],
        ],
        content: jsonEncode({
          'last_publish_date': '2024-01-01',
          'milestone_dates': ['2024-01-01', '2024-01-02'],
        }),
        createdAt: 1000,
      ),
    ]);

    await service.load();
    verify(() => mockEarnings.start()).called(1);
  });

  test('load decrypts remote event if raw is not found', () async {
    when(() => mockAccounts.getPublicKey()).thenReturn('pubkey1');
    when(
      () => mockCache.loadEvents(pubKeys: ['pubkey1'], kinds: [30078]),
    ).thenReturn([
      Nip01Event(
        pubKey: 'pubkey1',
        kind: 30078,
        tags: [
          ['d', 'zapbook:stats'],
        ],
        content: 'encrypted_content',
        createdAt: 1000,
      ),
    ]);

    final account = Account(
      type: AccountType.privateKey,
      signer: mockSigner,
      pubkey: 'pubkey1',
    );
    when(() => mockAccounts.getLoggedAccount()).thenReturn(account);
    when(
      () => mockSigner.decryptNip44(
        ciphertext: 'encrypted_content',
        senderPubKey: 'pubkey1',
      ),
    ).thenAnswer(
      (_) async => jsonEncode({
        'last_publish_date': '2024-01-01',
        'milestone_dates': ['2024-01-01'],
      }),
    );

    await service.load();
    verify(() => mockEarnings.start()).called(1);
  });

  test('recordMilestone writes to cache and syncs to relays', () async {
    when(() => mockAccounts.getPublicKey()).thenReturn('pubkey1');
    when(
      () => mockCache.loadEvents(pubKeys: ['pubkey1'], kinds: [30078]),
    ).thenReturn([]);
    when(() => mockCache.saveEvent(any())).thenReturn(null);

    final account = Account(
      type: AccountType.privateKey,
      signer: mockSigner,
      pubkey: 'pubkey1',
    );
    when(() => mockAccounts.getLoggedAccount()).thenReturn(account);
    when(
      () => mockSigner.encryptNip44(
        plaintext: any(named: 'plaintext'),
        recipientPubKey: 'pubkey1',
      ),
    ).thenAnswer((_) async => 'encrypted_content');
    when(
      () => mockBroadcast.broadcast(
        nostrEvent: any(named: 'nostrEvent'),
        specificRelays: any(named: 'specificRelays'),
      ),
    ).thenReturn(MockNdkBroadcastResponse());

    await service.load(); // Load first to enable _loaded
    service.recordMilestone();

    // Give async time to process unawaited syncToRelays
    await Future.delayed(Duration.zero);

    verify(
      () => mockCache.saveEvent(any()),
    ).called(2); // Once for raw (sync), once for encrypted
    verify(
      () => mockBroadcast.broadcast(
        nostrEvent: any(named: 'nostrEvent'),
        specificRelays: any(named: 'specificRelays'),
      ),
    ).called(1);
  });

  test('publishDailyHeartbeat broadcasts event and updates cache', () async {
    when(() => mockAccounts.getPublicKey()).thenReturn('pubkey1');
    when(
      () => mockBroadcast.broadcast(
        nostrEvent: any(named: 'nostrEvent'),
        specificRelays: any(named: 'specificRelays'),
      ),
    ).thenReturn(MockNdkBroadcastResponse());
    when(() => mockCache.saveEvent(any())).thenReturn(null);

    await service.publishDailyHeartbeat();

    verify(
      () => mockBroadcast.broadcast(
        nostrEvent: any(named: 'nostrEvent'),
        specificRelays: any(named: 'specificRelays'),
      ),
    ).called(1);
    verify(() => mockCache.saveEvent(any())).called(1);
  });

  test('publishDailyHeartbeat skips if already published today', () async {
    when(() => mockAccounts.getPublicKey()).thenReturn('pubkey1');
    when(
      () => mockCache.loadEvents(pubKeys: ['pubkey1'], kinds: [30078]),
    ).thenReturn([
      Nip01Event(
        pubKey: 'pubkey1',
        kind: 30078,
        tags: [
          ['d', 'zapbook:stats:raw'],
        ],
        content: jsonEncode({'last_publish_date': today()}),
        createdAt: 1000,
      ),
    ]);

    await service.load();
    await service.publishDailyHeartbeat();

    verifyNever(
      () => mockBroadcast.broadcast(
        nostrEvent: any(named: 'nostrEvent'),
        specificRelays: any(named: 'specificRelays'),
      ),
    );
  });
}
