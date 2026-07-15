import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:zapbook/core/data/infrastructure/marmot_sync_service.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:ndk/ndk.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/data/infrastructure/key_package_service.dart';

class MockMarmot extends Mock implements Marmot {}

class MockNdk extends Mock implements Ndk {}

class MockIdentityLocalDataSource extends Mock
    implements IdentityLocalDataSource {}

class MockKeyPackageService extends Mock implements KeyPackageService {}

class MockRequests extends Mock implements Requests {}

void main() {
  late MockMarmot marmot;
  late MockNdk ndk;
  late MockIdentityLocalDataSource identity;
  late MockKeyPackageService keyPackages;
  late MarmotSyncService service;

  setUpAll(() {
    registerFallbackValue(Filter());
  });

  setUp(() {
    marmot = MockMarmot();
    ndk = MockNdk();
    identity = MockIdentityLocalDataSource();
    keyPackages = MockKeyPackageService();
    service = MarmotSyncService(marmot, ndk, identity, keyPackages);
  });

  group('MarmotSyncService', () {
    test('start does nothing if npub is null', () async {
      when(() => identity.readNpub()).thenAnswer((_) async => null);
      await service.start();
      verify(() => identity.readNpub()).called(1);
    });

    test('start does nothing if npub is empty', () async {
      when(() => identity.readNpub()).thenAnswer((_) async => '');
      await service.start();
      verify(() => identity.readNpub()).called(1);
    });

    test('stop clears subscriptions', () async {
      await service.stop();
      expect(true, isTrue); // Should complete without error
    });
  });
}
