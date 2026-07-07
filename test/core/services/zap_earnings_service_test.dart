import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ndk/ndk.dart';
import 'package:zapbook/core/services/zap_earnings_service.dart';

class MockNdk extends Mock implements Ndk {}

class MockAccounts extends Mock implements Accounts {}

class MockRequests extends Mock implements Requests {}

class MockNdkResponse extends Mock implements NdkResponse {}

class FakeFilter extends Fake implements Filter {}

void main() {
  late MockNdk mockNdk;
  late MockAccounts mockAccounts;
  late MockRequests mockRequests;
  late ZapEarningsService service;

  setUpAll(() {
    registerFallbackValue(FakeFilter());
  });

  setUp(() {
    mockNdk = MockNdk();
    mockAccounts = MockAccounts();
    mockRequests = MockRequests();

    when(() => mockNdk.accounts).thenReturn(mockAccounts);
    when(() => mockNdk.requests).thenReturn(mockRequests);

    service = ZapEarningsService(mockNdk);
  });

  test('start does nothing if pubkey is null', () async {
    when(() => mockAccounts.getPublicKey()).thenReturn(null);
    await service.start();
    verifyNever(() => mockRequests.query(filter: any(named: 'filter')));
  });

  test('start backfills and listens if pubkey is present', () async {
    when(() => mockAccounts.getPublicKey()).thenReturn('pubkey1');

    final mockRequest = MockNdkResponse();
    when(() => mockRequest.future).thenAnswer((_) async => <Nip01Event>[]);
    when(
      () => mockRequests.query(filter: any(named: 'filter')),
    ).thenReturn(mockRequest);

    final mockSubscription = MockNdkResponse();
    when(() => mockSubscription.requestId).thenReturn('req-id-1');
    when(() => mockSubscription.stream).thenAnswer((_) => const Stream.empty());
    when(
      () => mockRequests.subscription(filter: any(named: 'filter')),
    ).thenReturn(mockSubscription);

    await service.start();

    // Should backfill for 2 kinds (ZapReceipt=9735 and Nutzap=9321)
    verify(() => mockRequests.query(filter: any(named: 'filter'))).called(2);
    // Should listen for 2 kinds
    verify(
      () => mockRequests.subscription(filter: any(named: 'filter')),
    ).called(2);
  });

  test(
    'ingests valid zap receipt and updates total and circle earnings',
    () async {
      when(() => mockAccounts.getPublicKey()).thenReturn('pubkey1');

      final receiptEvent = Nip01Event(
        pubKey: 'sender1',
        kind: ZapReceipt.kKind,
        tags: [
          ['bolt11', 'lnbc100n1...'],
          [
            'description',
            jsonEncode({
              'tags': [
                ['client', 'zapbook'],
                ['circle', 'circle-1'],
                ['amount', '10000'], // 10 sats in millisats
              ],
            }),
          ],
        ],
        content: '',
        createdAt: 1000,
      );

      final mockRequest = MockNdkResponse();
      // Return the event only once to avoid infinite loop of backfill
      var called = false;
      when(() => mockRequest.future).thenAnswer((_) async {
        if (!called) {
          called = true;
          return [receiptEvent];
        }
        return <Nip01Event>[];
      });

      when(
        () => mockRequests.query(filter: any(named: 'filter')),
      ).thenReturn(mockRequest);

      final mockSubscription = MockNdkResponse();
      when(() => mockSubscription.requestId).thenReturn('req-id-1');
      when(
        () => mockSubscription.stream,
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => mockRequests.subscription(filter: any(named: 'filter')),
      ).thenReturn(mockSubscription);

      await service.start();

      expect(service.totalEarned.value, 10);
      expect(service.earnedForCircle('circle-1'), 10);
    },
  );

  test('ingests nutzap and updates total', () async {
    when(() => mockAccounts.getPublicKey()).thenReturn('pubkey1');

    final nutzapEvent = Nip01Event(
      pubKey: 'sender1',
      kind: 9321,
      tags: [
        ['unit', 'msat'],
        [
          'proof',
          jsonEncode({'amount': 20000}),
        ], // 20 sats
      ],
      content: '',
      createdAt: 1000,
    );

    final mockRequest = MockNdkResponse();
    var queryCount = 0;
    when(() => mockRequest.future).thenAnswer((_) async {
      queryCount++;
      if (queryCount == 2) {
        return [nutzapEvent];
      }
      return <Nip01Event>[];
    });

    when(
      () => mockRequests.query(filter: any(named: 'filter')),
    ).thenReturn(mockRequest);

    final mockSubscription = MockNdkResponse();
    when(() => mockSubscription.requestId).thenReturn('req-id-1');
    when(() => mockSubscription.stream).thenAnswer((_) => const Stream.empty());
    when(
      () => mockRequests.subscription(filter: any(named: 'filter')),
    ).thenReturn(mockSubscription);

    await service.start();

    expect(service.totalEarned.value, 20);
    expect(service.earnedForCircle('circle-1'), 0);
  });

  test('skips events not belonging to zapbook', () async {
    when(() => mockAccounts.getPublicKey()).thenReturn('pubkey1');

    final receiptEvent = Nip01Event(
      pubKey: 'sender1',
      kind: ZapReceipt.kKind,
      tags: [
        ['bolt11', 'lnbc100n1...'],
        [
          'description',
          jsonEncode({
            'tags': [
              ['client', 'other-client'], // Not zapbook
              ['amount', '10000'],
            ],
          }),
        ],
      ],
      content: '',
      createdAt: 1000,
    );

    final mockRequest = MockNdkResponse();
    var called = false;
    when(() => mockRequest.future).thenAnswer((_) async {
      if (!called) {
        called = true;
        return [receiptEvent];
      }
      return <Nip01Event>[];
    });

    when(
      () => mockRequests.query(filter: any(named: 'filter')),
    ).thenReturn(mockRequest);

    final mockSubscription = MockNdkResponse();
    when(() => mockSubscription.requestId).thenReturn('req-id-1');
    when(() => mockSubscription.stream).thenAnswer((_) => const Stream.empty());
    when(
      () => mockRequests.subscription(filter: any(named: 'filter')),
    ).thenReturn(mockSubscription);

    await service.start();

    expect(service.totalEarned.value, 0);
  });

  test('does not process duplicate event ids', () async {
    when(() => mockAccounts.getPublicKey()).thenReturn('pubkey1');

    final receiptEvent = Nip01Event(
      pubKey: 'sender1',
      kind: ZapReceipt.kKind,
      tags: [
        ['bolt11', 'lnbc100n1...'],
        [
          'description',
          jsonEncode({
            'tags': [
              ['client', 'zapbook'],
              ['amount', '10000'],
            ],
          }),
        ],
      ],
      content: '',
      createdAt: 1000,
    );

    final mockRequest = MockNdkResponse();
    var queryCount = 0;
    when(() => mockRequest.future).thenAnswer((_) async {
      queryCount++;
      if (queryCount == 1) {
        return [receiptEvent, receiptEvent]; // duplicate event in stream
      }
      return <Nip01Event>[];
    });

    when(
      () => mockRequests.query(filter: any(named: 'filter')),
    ).thenReturn(mockRequest);

    final mockSubscription = MockNdkResponse();
    when(() => mockSubscription.requestId).thenReturn('req-id-1');
    when(() => mockSubscription.stream).thenAnswer((_) => const Stream.empty());
    when(
      () => mockRequests.subscription(filter: any(named: 'filter')),
    ).thenReturn(mockSubscription);

    await service.start();

    // Should only count once: 10 sats
    expect(service.totalEarned.value, 10);
  });

  test('subscribes and updates total earned when new events arrive', () async {
    when(() => mockAccounts.getPublicKey()).thenReturn('pubkey1');

    final mockRequest = MockNdkResponse();
    when(() => mockRequest.future).thenAnswer((_) async => <Nip01Event>[]);
    when(
      () => mockRequests.query(filter: any(named: 'filter')),
    ).thenReturn(mockRequest);

    final streamController = StreamController<Nip01Event>();

    final mockSubscription = MockNdkResponse();
    when(() => mockSubscription.requestId).thenReturn('req-id-1');
    when(
      () => mockSubscription.stream,
    ).thenAnswer((_) => streamController.stream);
    when(
      () => mockRequests.subscription(filter: any(named: 'filter')),
    ).thenReturn(mockSubscription);

    await service.start();
    expect(service.totalEarned.value, 0);

    final receiptEvent = Nip01Event(
      pubKey: 'sender1',
      kind: ZapReceipt.kKind,
      tags: [
        ['bolt11', 'lnbc500n1...'],
        [
          'description',
          jsonEncode({
            'tags': [
              ['client', 'zapbook'],
              ['amount', '50000'], // 50 sats
            ],
          }),
        ],
      ],
      content: '',
      createdAt: 1000,
    );

    streamController.add(receiptEvent);

    // Wait for stream to be processed
    await Future.delayed(Duration.zero);

    expect(service.totalEarned.value, 50);
  });

  test('dispose cancels subscriptions', () async {
    when(() => mockAccounts.getPublicKey()).thenReturn('pubkey1');

    final mockRequest = MockNdkResponse();
    when(() => mockRequest.future).thenAnswer((_) async => <Nip01Event>[]);
    when(
      () => mockRequests.query(filter: any(named: 'filter')),
    ).thenReturn(mockRequest);

    final mockSubscription = MockNdkResponse();
    when(() => mockSubscription.requestId).thenReturn('req-id-1');
    when(() => mockSubscription.stream).thenAnswer((_) => const Stream.empty());
    when(
      () => mockRequests.subscription(filter: any(named: 'filter')),
    ).thenReturn(mockSubscription);

    when(
      () => mockRequests.closeSubscription('req-id-1'),
    ).thenAnswer((_) async {});

    await service.start();
    service.dispose();

    verify(() => mockRequests.closeSubscription('req-id-1')).called(2);
  });
}
