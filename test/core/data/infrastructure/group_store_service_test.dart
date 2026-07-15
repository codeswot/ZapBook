import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zapbook/core/data/infrastructure/group_store_service.dart';
import 'package:zapbook/core/data/infrastructure/marmot_sync_service.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/data/infrastructure/blossom_service.dart';
import 'package:zapbook/core/data/infrastructure/group_envelope_service.dart';

class MockMarmotSyncService extends Mock implements MarmotSyncService {}

class MockMarmot extends Mock implements Marmot {}

class MockIdentityLocalDataSource extends Mock
    implements IdentityLocalDataSource {}

class MockBlossomService extends Mock implements BlossomService {}

class MockGroupEnvelopeService extends Mock implements GroupEnvelopeService {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late MockMarmotSyncService marmotSync;
  late MockMarmot marmot;
  late MockIdentityLocalDataSource identity;
  late MockBlossomService blossom;
  late MockGroupEnvelopeService envelope;
  late MockSharedPreferences prefs;
  late GroupStoreService service;

  setUp(() {
    marmotSync = MockMarmotSyncService();
    marmot = MockMarmot();
    identity = MockIdentityLocalDataSource();
    blossom = MockBlossomService();
    envelope = MockGroupEnvelopeService();
    prefs = MockSharedPreferences();

    when(() => marmotSync.onGroup).thenAnswer((_) => const Stream.empty());
    when(() => marmotSync.onSync).thenAnswer((_) => const Stream.empty());
    when(() => marmot.listGroups()).thenAnswer((_) async => []);
    when(() => prefs.getStringList(any())).thenReturn([]);

    service = GroupStoreService(
      marmotSync,
      marmot,
      identity,
      blossom,
      envelope,
      prefs,
    );
  });

  group('GroupStoreService', () {
    test('createGroup throws if no npub', () async {
      when(() => identity.readNpub()).thenAnswer((_) async => null);

      expect(
        () => service.createGroup(
          name: 'Test',
          description: 'Desc',
          memberKeyPackageEventJsons: [],
        ),
        throwsException,
      );
    });

    test('deleteGroup stores deleted id', () async {
      when(() => marmot.deleteGroup(any())).thenAnswer((_) async {});
      when(
        () => prefs.setStringList(any(), any()),
      ).thenAnswer((_) async => true);

      await service.deleteGroup('group123');

      verify(
        () => prefs.setStringList('deleted_groups', ['group123']),
      ).called(1);
    });
  });
}
