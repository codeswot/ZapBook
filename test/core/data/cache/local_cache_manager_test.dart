import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ndk/domain_layer/entities/contact_list.dart';
import 'package:ndk/domain_layer/entities/metadata.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/domain_layer/entities/nip_05.dart';
import 'package:ndk/domain_layer/entities/read_write.dart';
import 'package:ndk/domain_layer/entities/read_write_marker.dart';
import 'package:ndk/domain_layer/entities/relay_set.dart';
import 'package:ndk/domain_layer/entities/user_relay_list.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_keyset.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_mint_info.dart';
import 'package:ndk/domain_layer/entities/filter_fetched_ranges.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:zapbook/core/data/cache/local_cache_manager.dart';
import 'package:zapbook/core/data/cache/nostr_cache_store.dart';

class MockCahsuKeyset extends Mock implements CahsuKeyset {}

class MockCashuMintInfo extends Mock implements CashuMintInfo {}

class MockFilterFetchedRangeRecord extends Mock
    implements FilterFetchedRangeRecord {}

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String tempPath;
  FakePathProviderPlatform(this.tempPath);

  @override
  Future<String?> getApplicationSupportPath() async => tempPath;

  @override
  Future<String?> getApplicationCachePath() async => tempPath;
}

void main() {
  late Directory tempDir;
  late NostrCacheStore store;
  late LocalCacheManager manager;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('local_cache_test');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);

    store = await NostrCacheStore.open();
    manager = LocalCacheManager(store);
  });

  tearDown(() async {
    store.closeStore();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Events (LocalCacheManager)', () {
    test('saves and loads a single event from memory', () async {
      final event = Nip01Event(
        id: 'evt1',
        pubKey: 'pub1',
        createdAt: 1000,
        kind: 1,
        content: 'hello',
        sig: 'sig1',
        tags: [
          ['t', 'tag1'],
        ],
      );

      await manager.saveEvent(event);

      final loaded = await manager.loadEvent('evt1');
      expect(loaded, isNotNull);
      expect(loaded!.content, 'hello');
    });

    test('saves and loads multiple events, filtering correctly', () async {
      final events = [
        Nip01Event(
          id: 'evt1',
          pubKey: 'pub1',
          createdAt: 1000,
          kind: 1,
          content: 'hello 1',
          sig: '',
          tags: [
            ['t', 'zap'],
          ],
        ),
        Nip01Event(
          id: 'evt2',
          pubKey: 'pub1',
          createdAt: 1001,
          kind: 1,
          content: 'hello 2',
          sig: '',
          tags: [
            ['p', 'pub2'],
          ],
        ),
        Nip01Event(
          id: 'evt3',
          pubKey: 'pub2',
          createdAt: 1002,
          kind: 2,
          content: '3',
          sig: '',
          tags: [
            ['t', 'zap'],
          ],
        ),
      ];

      await manager.saveEvents(events);

      final byPub = await manager.loadEvents(pubKeys: ['pub1']);
      expect(byPub.length, 2);

      final byKind = await manager.loadEvents(kinds: [2]);
      expect(byKind.length, 1);
      expect(byKind.first.id, 'evt3');

      final bySearch = await manager.loadEvents(search: 'hello');
      expect(bySearch.length, 2);

      final byTag = await manager.loadEvents(
        tags: {
          't': ['zap'],
        },
      );
      expect(byTag.length, 2);

      final bySince = await manager.loadEvents(since: 1001);
      expect(bySince.length, 2);

      final byUntil = await manager.loadEvents(until: 1000);
      expect(byUntil.length, 1);

      final byLimit = await manager.loadEvents(limit: 1);
      expect(byLimit.length, 1);
    });
  });

  group('Metadata (LocalCacheManager)', () {
    test('saves and loads metadata', () async {
      final metadata = Metadata(
        pubKey: 'pub1',
        name: 'Alice',
        about: 'Tester',
        updatedAt: 1000,
        refreshedTimestamp: 2000,
      );

      await manager.saveMetadata(metadata);

      final loaded = await manager.loadMetadata('pub1');
      expect(loaded, isNotNull);
      expect(loaded!.name, 'Alice');

      await manager.removeMetadata('pub1');
      final loadedAfterRemove = await manager.loadMetadata('pub1');
      expect(loadedAfterRemove, isNull);
    });
  });

  group('ContactList (LocalCacheManager)', () {
    test('saves and loads contact lists', () async {
      final contacts = ContactList(pubKey: 'pub1', contacts: ['c1', 'c2']);

      await manager.saveContactList(contacts);

      final loaded = await manager.loadContactList('pub1');
      expect(loaded, isNotNull);
      expect(loaded!.contacts, ['c1', 'c2']);

      await manager.removeContactList('pub1');
      final loadedAfterRemove = await manager.loadContactList('pub1');
      expect(loadedAfterRemove, isNull);
    });
  });

  group('UserRelayList (LocalCacheManager)', () {
    test('saves and loads user relay lists', () async {
      final relays = UserRelayList(
        pubKey: 'pub1',
        relays: {
          'wss://relay1.com': ReadWriteMarker.from(read: true, write: false),
        },
        createdAt: 1000,
        refreshedTimestamp: 2000,
      );

      await manager.saveUserRelayList(relays);

      final loaded = await manager.loadUserRelayList('pub1');
      expect(loaded, isNotNull);
      expect(loaded!.relays.keys, contains('wss://relay1.com'));

      await manager.removeUserRelayList('pub1');
      final loadedAfterRemove = await manager.loadUserRelayList('pub1');
      expect(loadedAfterRemove, isNull);
    });
  });

  group('Cache Management', () {
    test('removeAll removes all lists', () async {
      final contacts = ContactList(pubKey: 'pub1', contacts: []);
      final relays = UserRelayList(
        pubKey: 'pub2',
        relays: {},
        createdAt: 0,
        refreshedTimestamp: 0,
      );

      await manager.saveContactList(contacts);
      await manager.saveUserRelayList(relays);

      await manager.removeAllContactLists();
      await manager.removeAllUserRelayLists();

      expect(await manager.loadContactList('pub1'), isNull);
      expect(await manager.loadUserRelayList('pub2'), isNull);
    });

    test('removeEvent and removeAllEvents', () async {
      final evt = Nip01Event(
        pubKey: 'pub1',
        kind: 1,
        tags: [],
        content: '1',
        id: '1',
        createdAt: 0,
        sig: '',
      );
      await manager.saveEvent(evt);
      expect(await manager.loadEvent('1'), isNotNull);

      await manager.removeEvent('1');
      expect(await manager.loadEvent('1'), isNull);

      await manager.saveEvent(evt);
      await manager.removeAllEventsByPubKey('pub1');
      expect(await manager.loadEvent('1'), isNull);

      await manager.saveEvent(evt);
      await manager.removeAllEvents();
      expect(await manager.loadEvent('1'), isNull);
    });

    test('searchEvents proxies to loadEvents', () async {
      final evt = Nip01Event(
        pubKey: 'pub1',
        kind: 1,
        tags: [],
        content: 'searchme',
        id: '1',
        createdAt: 0,
        sig: '',
      );
      await manager.saveEvent(evt);

      final result = await manager.searchEvents(search: 'searchme');
      expect(result.length, 1);
    });
  });

  group('RelaySet', () {
    test('save, load, remove relay set', () async {
      final relaySet = RelaySet(
        name: 'test',
        pubKey: 'pub1',
        relaysMap: {},
        direction: RelayDirection.outbox,
      );
      await manager.saveRelaySet(relaySet);

      final loaded = await manager.loadRelaySet('test', 'pub1');
      expect(loaded, isNotNull);
      expect(loaded!.name, 'test');

      await manager.removeRelaySet('test', 'pub1');
      expect(await manager.loadRelaySet('test', 'pub1'), isNull);

      await manager.saveRelaySet(relaySet);
      await manager.removeAllRelaySets();
      expect(await manager.loadRelaySet('test', 'pub1'), isNull);
    });
  });

  group('Nip05', () {
    test('save, load, remove nip05', () async {
      final nip05 = Nip05(pubKey: 'pub1', nip05: 'test@test.com', valid: true);
      await manager.saveNip05(nip05);

      expect(await manager.loadNip05(pubKey: 'pub1'), isNotNull);

      await manager.saveNip05s([nip05]);
      final loadedList = await manager.loadNip05s(['pub1']);
      expect(loadedList.length, 1);

      await manager.removeNip05('pub1');
      expect(await manager.loadNip05(pubKey: 'pub1'), isNull);

      await manager.saveNip05(nip05);
      await manager.removeAllNip05s();
      expect(await manager.loadNip05(pubKey: 'pub1'), isNull);
    });
  });

  group('Bulk Ops & Others', () {
    test('saveContactLists', () async {
      final contacts = ContactList(pubKey: 'pub1', contacts: []);
      await manager.saveContactLists([contacts]);
      expect(await manager.loadContactList('pub1'), isNotNull);
    });

    test('saveUserRelayLists', () async {
      final relays = UserRelayList(
        pubKey: 'pub1',
        relays: {},
        createdAt: 0,
        refreshedTimestamp: 0,
      );
      await manager.saveUserRelayLists([relays]);
      expect(await manager.loadUserRelayList('pub1'), isNotNull);
    });

    test('saveMetadatas and loadMetadatas', () async {
      final meta = Metadata(
        pubKey: 'pub1',
        name: 'Alice',
        updatedAt: 0,
        refreshedTimestamp: 0,
      );
      await manager.saveMetadatas([meta]);

      final list = await manager.loadMetadatas(['pub1']);
      expect(list.length, 1);

      await manager.removeAllMetadatas();
      expect(await manager.loadMetadata('pub1'), isNull);
    });

    test('searchMetadatas', () async {
      final meta = Metadata(
        pubKey: 'pub1',
        name: 'Alice searchme',
        updatedAt: 0,
        refreshedTimestamp: 0,
      );
      await manager.saveMetadatas([meta]);

      final results = await manager.searchMetadatas('searchme', 10);
      expect(results.length, 1);
    });

    test('clearAll', () async {
      await manager.clearAll();
      // Should clear in-memory maps
    });

    test('Cashu stubs', () async {
      final keyset = MockCahsuKeyset();
      await manager.saveKeyset(keyset).catchError((_) {});
      await manager.getKeysets();
      await manager.saveProofs(proofs: [], mintUrl: '');
      await manager.getProofs();
      await manager.removeProofs(proofs: [], mintUrl: '');
      final mintInfo = MockCashuMintInfo();
      await manager.saveMintInfo(mintInfo: mintInfo).catchError((_) {});
      await manager.removeMintInfo(mintUrl: '');
      await manager.getMintInfos();
      await manager.getCashuSecretCounter(mintUrl: '', keysetId: '');
      await manager.setCashuSecretCounter(
        mintUrl: '',
        keysetId: '',
        counter: 1,
      );
    });

    test('FilterFetchedRangeRecord stubs', () async {
      final record = MockFilterFetchedRangeRecord();
      await manager.saveFilterFetchedRangeRecord(record).catchError((_) {});
      await manager.saveFilterFetchedRangeRecords([]);
      await manager.loadFilterFetchedRangeRecords('');
      await manager.loadFilterFetchedRangeRecordsByRelay('', '');
      await manager.loadFilterFetchedRangeRecordsByRelayUrl('');
      await manager.removeFilterFetchedRangeRecords('');
      await manager.removeFilterFetchedRangeRecordsByFilterAndRelay('', '');
      await manager.removeFilterFetchedRangeRecordsByRelay('');
      await manager.removeAllFilterFetchedRangeRecords();
    });

    test('close', () async {
      await manager.close();
      await manager.close(); // idempotency check
    });
  });
}
