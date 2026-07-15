import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ndk/ndk.dart';

import 'package:zapbook/core/data/infrastructure/contact_service.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/data/infrastructure/nostr_service.dart';

class MockNostrService extends Mock implements NostrService {}

class MockIdentityLocalDataSource extends Mock
    implements IdentityLocalDataSource {}

void main() {
  late MockNostrService nostr;
  late MockIdentityLocalDataSource identity;
  late ContactService service;

  setUp(() {
    nostr = MockNostrService();
    identity = MockIdentityLocalDataSource();
    service = ContactService(nostr, identity);
  });

  group('ContactService', () {
    test('isValidNpub rejects malformed npub', () {
      expect(service.isValidNpub('npub12345'), isFalse);
      expect(service.isValidNpub('notanpub'), isFalse);
    });

    test('isValidNpub accepts a well-formed npub', () {
      final npub = Nip19.encodePubKey('a' * 64);
      expect(service.isValidNpub(npub), isTrue);
    });

    test('add throws if npub is same as my npub', () async {
      when(() => identity.readNpub()).thenAnswer((_) async => 'same_npub');

      expect(() => service.add('same_npub'), throwsException);
    });

    test('remove broadcasts contact removal when pubkey exists', () async {
      final hex = 'a' * 64;
      final npub = Nip19.encodePubKey(hex);
      when(() => nostr.pubkey).thenReturn('mypubkey');
      when(
        () => nostr.broadcastRemoveContact(any()),
      ).thenAnswer((_) async => null);
      when(() => nostr.getCachedContactList(any())).thenReturn(null);
      when(() => nostr.getContactList(any())).thenAnswer((_) async => null);

      await service.remove(npub);

      verify(() => nostr.broadcastRemoveContact(hex)).called(1);
    });
  });
}
