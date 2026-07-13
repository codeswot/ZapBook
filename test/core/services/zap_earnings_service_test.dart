import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ndk/ndk.dart';
import 'package:zapbook/core/services/zap_earnings_service.dart';
import 'package:zapbook/core/data/dao/zap_sats_earnings_dao.dart';

class MockNdk extends Mock implements Ndk {}

class MockAccounts extends Mock implements Accounts {}

class MockRequests extends Mock implements Requests {}

class MockNdkResponse extends Mock implements NdkResponse {}

class MockZapSatsEarningsDao extends Mock implements ZapSatsEarningsDao {}

class FakeFilter extends Fake implements Filter {}

class FakeZapSatsEarningsRecord extends Fake implements ZapSatsEarningsRecord {}

void main() {
  late MockNdk mockNdk;
  late MockAccounts mockAccounts;
  late MockRequests mockRequests;
  late MockZapSatsEarningsDao mockEarningsDao;
  late ZapEarningsService service;

  setUpAll(() {
    registerFallbackValue(FakeFilter());
    registerFallbackValue(FakeZapSatsEarningsRecord());
  });

  setUp(() {
    mockNdk = MockNdk();
    mockAccounts = MockAccounts();
    mockRequests = MockRequests();
    mockEarningsDao = MockZapSatsEarningsDao();

    when(() => mockNdk.accounts).thenReturn(mockAccounts);
    when(() => mockNdk.requests).thenReturn(mockRequests);

    when(
      () => mockEarningsDao.getLastZapTimestamp(),
    ).thenAnswer((_) async => null);
    when(() => mockEarningsDao.insertZap(any())).thenAnswer((_) async {});

    service = ZapEarningsService(mockNdk, mockEarningsDao);
  });

  test('start does nothing if pubkey is null', () async {
    when(() => mockAccounts.getPublicKey()).thenReturn(null);
    await service.start();
    verifyNever(() => mockRequests.subscription(filter: any(named: 'filter')));
  });

  test('start listens for events if pubkey is present', () async {
    when(() => mockAccounts.getPublicKey()).thenReturn('pubkey1');

    final mockSubscription = MockNdkResponse();
    when(() => mockSubscription.requestId).thenReturn('req-id-1');
    when(() => mockSubscription.stream).thenAnswer((_) => const Stream.empty());
    when(
      () => mockRequests.subscription(filter: any(named: 'filter')),
    ).thenReturn(mockSubscription);

    await service.start();

    // Should listen for 2 kinds (ZapReceipt=9735 and Nutzap=9321)
    verify(
      () => mockRequests.subscription(filter: any(named: 'filter')),
    ).called(2);
  });

  test('ingests valid zap receipt from subscription', () async {
    when(() => mockAccounts.getPublicKey()).thenReturn('pubkey1');

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

    streamController.add(receiptEvent);

    await Future.delayed(const Duration(milliseconds: 10));

    verify(() => mockEarningsDao.insertZap(any())).called(1);
  });

  test('skips events not belonging to zapbook', () async {
    when(() => mockAccounts.getPublicKey()).thenReturn('pubkey1');

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

    streamController.add(receiptEvent);

    await Future.delayed(const Duration(milliseconds: 10));

    verifyNever(() => mockEarningsDao.insertZap(any()));
  });

  test('dispose cancels subscriptions', () async {
    when(() => mockAccounts.getPublicKey()).thenReturn('pubkey1');

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
