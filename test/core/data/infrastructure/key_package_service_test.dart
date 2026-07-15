import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:zapbook/core/data/infrastructure/key_package_service.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:ndk/ndk.dart';

class MockMarmot extends Mock implements Marmot {}

class MockIdentityLocalDataSource extends Mock
    implements IdentityLocalDataSource {}

class MockNdk extends Mock implements Ndk {}

class MockRequests extends Mock implements Requests {}

void main() {
  late MockMarmot marmot;
  late MockIdentityLocalDataSource identity;
  late MockNdk ndk;
  late MockRequests requests;
  late KeyPackageService service;

  setUp(() {
    marmot = MockMarmot();
    identity = MockIdentityLocalDataSource();
    ndk = MockNdk();
    requests = MockRequests();

    when(() => ndk.requests).thenReturn(requests);

    service = KeyPackageService(marmot, identity, ndk);
  });

  group('KeyPackageService', () {
    test('publishIfNeeded returns false if npub is null', () async {
      when(() => identity.readNpub()).thenAnswer((_) async => null);
      when(() => identity.readNsec()).thenAnswer((_) async => null);

      final result = await service.publishIfNeeded();
      expect(result, isFalse);
    });

    test('forceRotate returns false if npub is null', () async {
      when(() => identity.readNpub()).thenAnswer((_) async => null);
      when(() => identity.readNsec()).thenAnswer((_) async => null);

      final result = await service.forceRotate();
      expect(result, isFalse);
    });
  });
}
