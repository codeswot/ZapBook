import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/domain_layer/entities/contact_list.dart';
import 'package:ndk/domain_layer/entities/metadata.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/domain_layer/entities/read_write_marker.dart';
import 'package:ndk/domain_layer/entities/user_relay_list.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:zapbook/core/data/cache/local_cache_manager.dart';
import 'package:zapbook/core/data/cache/nostr_cache_store.dart';

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

      // Verify it's in manager
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
          content: '1',
          sig: '',
          tags: [],
        ),
        Nip01Event(
          id: 'evt2',
          pubKey: 'pub1',
          createdAt: 1001,
          kind: 1,
          content: '2',
          sig: '',
          tags: [],
        ),
        Nip01Event(
          id: 'evt3',
          pubKey: 'pub2',
          createdAt: 1002,
          kind: 2,
          content: '3',
          sig: '',
          tags: [],
        ),
      ];

      await manager.saveEvents(events);

      final byPub = await manager.loadEvents(pubKeys: ['pub1']);
      // the manager returns from both mem and db, merging them.
      expect(byPub.length, 2);

      final byKind = await manager.loadEvents(kinds: [2]);
      expect(byKind.length, 1);
      expect(byKind.first.id, 'evt3');
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

      // Verify removal
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
  });
}
