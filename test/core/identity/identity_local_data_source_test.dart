import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/identity/active_account.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/data/infrastructure/secure_storage_service.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late MockSecureStorageService storage;
  late IdentityLocalDataSource dataSource;

  setUp(() {
    storage = MockSecureStorageService();
    dataSource = IdentityLocalDataSource(storage);
    ActiveAccount.setNpub(null); // Reset global state
    when(() => storage.read('signer_meta')).thenAnswer((_) async => null);
    when(() => storage.write('signer_meta', any())).thenAnswer((_) async {});
  });

  group('IdentityLocalDataSource', () {
    test('addAccount and listNpubs', () async {
      when(() => storage.read('accounts')).thenAnswer((_) async => null);
      when(() => storage.write('accounts', any())).thenAnswer((_) async {});

      await dataSource.addAccount(
        npub: 'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6',
        nsec: 'nsec1',
      );

      verify(
        () => storage.write(
          'accounts',
          jsonEncode({
            'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6':
                'nsec1',
          }),
        ),
      ).called(1);

      final npubs = await dataSource.listNpubs();
      expect(npubs, [
        'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6',
      ]);
    });

    test('listNpubs handles corrupted json', () async {
      when(() => storage.read('accounts')).thenAnswer((_) async => 'not json');

      final npubs = await dataSource.listNpubs();
      expect(npubs, isEmpty);
    });

    test('setActive sets active account and writes to storage', () async {
      when(
        () => storage.write(
          ActiveAccount.activeNpubKey,
          'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6',
        ),
      ).thenAnswer((_) async {});

      await dataSource.setActive(
        'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6',
      );

      verify(
        () => storage.write(
          ActiveAccount.activeNpubKey,
          'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6',
        ),
      ).called(1);
      expect(
        ActiveAccount.currentNpub,
        'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6',
      );
    });

    test('removeAccount deletes account and clears active if active', () async {
      when(() => storage.read('accounts')).thenAnswer(
        (_) async => jsonEncode({
          'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6':
              'nsec1',
          'npub1qawh0yhq7px5a80txyv2v3x0r4mzhmtz0wrtedpukmquqsz0uems60ntc0':
              'nsec2',
        }),
      );
      when(() => storage.write('accounts', any())).thenAnswer((_) async {});
      when(
        () => storage.delete(ActiveAccount.activeNpubKey),
      ).thenAnswer((_) async {});
      ActiveAccount.setNpub(
        'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6',
      );

      await dataSource.removeAccount(
        'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6',
      );

      verify(
        () => storage.write(
          'accounts',
          jsonEncode({
            'npub1qawh0yhq7px5a80txyv2v3x0r4mzhmtz0wrtedpukmquqsz0uems60ntc0':
                'nsec2',
          }),
        ),
      ).called(1);
      verify(() => storage.delete(ActiveAccount.activeNpubKey)).called(1);
      expect(ActiveAccount.currentNpub, isNull);
    });

    test('write sets active and adds account', () async {
      when(() => storage.read('accounts')).thenAnswer((_) async => null);
      when(() => storage.write('accounts', any())).thenAnswer((_) async {});
      when(
        () => storage.write(
          ActiveAccount.activeNpubKey,
          'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6',
        ),
      ).thenAnswer((_) async {});

      await dataSource.write(
        npub: 'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6',
        nsec: 'nsec1',
      );

      verify(
        () => storage.write(
          'accounts',
          jsonEncode({
            'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6':
                'nsec1',
          }),
        ),
      ).called(1);
      verify(
        () => storage.write(
          ActiveAccount.activeNpubKey,
          'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6',
        ),
      ).called(1);
      expect(
        ActiveAccount.currentNpub,
        'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6',
      );
    });

    test('readNpub returns cached or reads storage', () async {
      when(() => storage.read(ActiveAccount.activeNpubKey)).thenAnswer(
        (_) async =>
            'npub1qawh0yhq7px5a80txyv2v3x0r4mzhmtz0wrtedpukmquqsz0uems60ntc0',
      );

      var res = await dataSource.readNpub();
      expect(
        res,
        'npub1qawh0yhq7px5a80txyv2v3x0r4mzhmtz0wrtedpukmquqsz0uems60ntc0',
      );
      expect(
        ActiveAccount.currentNpub,
        'npub1qawh0yhq7px5a80txyv2v3x0r4mzhmtz0wrtedpukmquqsz0uems60ntc0',
      );

      res = await dataSource.readNpub();
      expect(
        res,
        'npub1qawh0yhq7px5a80txyv2v3x0r4mzhmtz0wrtedpukmquqsz0uems60ntc0',
      ); // Returns cached
      verify(
        () => storage.read(ActiveAccount.activeNpubKey),
      ).called(1); // Only called once
    });

    test('readNsec returns null if no active npub', () async {
      when(
        () => storage.read(ActiveAccount.activeNpubKey),
      ).thenAnswer((_) async => null);

      final res = await dataSource.readNsec();
      expect(res, isNull);
    });

    test('readNsec returns correct nsec', () async {
      when(() => storage.read(ActiveAccount.activeNpubKey)).thenAnswer(
        (_) async =>
            'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6',
      );
      when(() => storage.read('accounts')).thenAnswer(
        (_) async => jsonEncode({
          'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6':
              'nsec1',
        }),
      );

      final res = await dataSource.readNsec();
      expect(res, 'nsec1');
    });

    test('readDtag and writeDtag proxies to storage', () async {
      ActiveAccount.setNpub(
        'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6',
      );
      when(() => storage.write(any(), any())).thenAnswer((_) async {});
      when(() => storage.read(any())).thenAnswer((_) async => 'val');

      await dataSource.writeDtag('mykey', 'val');
      verify(() => storage.write(any(), 'val')).called(1);

      final res = await dataSource.readDtag('mykey');
      expect(res, 'val');
      verify(() => storage.read(any())).called(1);
    });

    test('clear removes active', () async {
      ActiveAccount.setNpub(
        'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6',
      );
      when(
        () => storage.delete(ActiveAccount.activeNpubKey),
      ).thenAnswer((_) async {});

      await dataSource.clear();

      verify(() => storage.delete(ActiveAccount.activeNpubKey)).called(1);
      expect(ActiveAccount.currentNpub, isNull);
    });
  });
}
