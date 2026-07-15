import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ndk/ndk.dart';

import 'package:zapbook/core/data/cache/nostr_cache_store.dart';
import 'package:zapbook/core/data/infrastructure/nostr_service.dart';

class MockNdk extends Mock implements Ndk {}

class MockNostrCacheStore extends Mock implements NostrCacheStore {}

class MockAccounts extends Mock implements Accounts {}

class MockAccount extends Mock implements Account {}

class MockEventSigner extends Mock implements EventSigner {}

class MockBroadcast extends Mock implements Broadcast {}

class FakeNip01Event extends Fake implements Nip01Event {}

class FakeNdkBroadcastResponse extends Fake implements NdkBroadcastResponse {}

void main() {
  late MockNdk ndk;
  late MockNostrCacheStore store;
  late MockAccounts accounts;
  late MockAccount account;
  late MockEventSigner signer;
  late MockBroadcast broadcast;
  late NostrService service;

  const npub =
      'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6';
  final hex = Nip19.decode(npub);

  setUpAll(() {
    registerFallbackValue(FakeNip01Event());
  });

  setUp(() {
    ndk = MockNdk();
    store = MockNostrCacheStore();
    accounts = MockAccounts();
    account = MockAccount();
    signer = MockEventSigner();
    broadcast = MockBroadcast();

    when(() => ndk.accounts).thenReturn(accounts);
    when(() => ndk.broadcast).thenReturn(broadcast);
    when(() => accounts.getLoggedAccount()).thenReturn(account);
    when(() => account.signer).thenReturn(signer);
    when(() => account.pubkey).thenReturn('my_pubkey');
    when(() => signer.canSign()).thenReturn(true);
    when(
      () => signer.sign(any()),
    ).thenAnswer((inv) async => inv.positionalArguments[0] as Nip01Event);
    when(
      () => broadcast.broadcast(
        nostrEvent: any(named: 'nostrEvent'),
        specificRelays: any(named: 'specificRelays'),
      ),
    ).thenReturn(FakeNdkBroadcastResponse());

    service = NostrService(ndk, store);
  });

  test(
    'publishNote broadcasts a kind 1 note with a p tag per mention',
    () async {
      await service.publishNote('hello world', mentionNpubs: [npub]);

      final event =
          verify(
                () => broadcast.broadcast(
                  nostrEvent: captureAny(named: 'nostrEvent'),
                  specificRelays: any(named: 'specificRelays'),
                ),
              ).captured.single
              as Nip01Event;

      expect(event.kind, 1);
      expect(event.content, 'hello world');
      expect(event.tags, contains(equals(['p', hex])));
    },
  );

  test('publishNote skips invalid mentions', () async {
    await service.publishNote('hi', mentionNpubs: const ['not-an-npub', '']);

    final event =
        verify(
              () => broadcast.broadcast(
                nostrEvent: captureAny(named: 'nostrEvent'),
                specificRelays: any(named: 'specificRelays'),
              ),
            ).captured.single
            as Nip01Event;

    expect(event.tags, isEmpty);
  });

  test('publishNote throws when no signer is available', () async {
    when(() => signer.canSign()).thenReturn(false);

    expect(() => service.publishNote('hi'), throwsStateError);
  });
}
