import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/domain_layer/entities/contact_list.dart';
import 'package:ndk/domain_layer/entities/metadata.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/domain_layer/entities/read_write_marker.dart';
import 'package:ndk/domain_layer/entities/user_relay_list.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
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

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('nostr_cache_test');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);

    store = await NostrCacheStore.open();
  });

  tearDown(() async {
    store.closeStore();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Events', () {
    test('saves and loads a single event', () {
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

      store.saveEvent(event);

      final loaded = store.loadEvent('evt1');
      expect(loaded, isNotNull);
      expect(loaded!.id, 'evt1');
      expect(loaded.pubKey, 'pub1');
      expect(loaded.content, 'hello');
      expect(loaded.tags.first, ['t', 'tag1']);
    });

    test('saves and loads multiple events', () {
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
      ];

      store.saveEvents(events);

      final loaded1 = store.loadEvent('evt1');
      final loaded2 = store.loadEvent('evt2');
      expect(loaded1, isNotNull);
      expect(loaded2, isNotNull);
    });

    test('loadEvents filters correctly', () {
      store.saveEvents([
        Nip01Event(
          id: 'evt1',
          pubKey: 'pubA',
          createdAt: 10,
          kind: 1,
          content: 'hello world',
          sig: '',
          tags: [
            ['t', 'test'],
          ],
        ),
        Nip01Event(
          id: 'evt2',
          pubKey: 'pubA',
          createdAt: 20,
          kind: 1,
          content: 'hello 2',
          sig: '',
          tags: [
            ['p', 'test2'],
          ],
        ),
        Nip01Event(
          id: 'evt3',
          pubKey: 'pubB',
          createdAt: 30,
          kind: 2,
          content: '',
          sig: '',
          tags: [
            ['t', 'test'],
          ],
        ),
      ]);

      final byPub = store.loadEvents(pubKeys: ['pubA']);
      expect(byPub.length, 2);

      final byKind = store.loadEvents(kinds: [2]);
      expect(byKind.length, 1);
      expect(byKind.first.id, 'evt3');

      final bySearch = store.loadEvents(search: 'hello');
      expect(bySearch.length, 2);

      final byTag = store.loadEvents(
        tags: {
          't': ['test'],
        },
      );
      expect(byTag.length, 2);

      final bySince = store.loadEvents(since: 20);
      expect(bySince.length, 2);

      final byUntil = store.loadEvents(until: 20);
      expect(byUntil.length, 2);

      final byLimit = store.loadEvents(limit: 1);
      expect(byLimit.length, 1);
    });
  });

  group('Metadata', () {
    test('saves and loads metadata', () {
      final metadata = Metadata(
        pubKey: 'pub1',
        name: 'Alice',
        about: 'Tester',
        updatedAt: 1000,
        refreshedTimestamp: 2000,
      );

      store.saveMetadata(metadata);

      final loaded = store.loadMetadata('pub1');
      expect(loaded, isNotNull);
      expect(loaded!.pubKey, 'pub1');
      expect(loaded.name, 'Alice');
      expect(loaded.about, 'Tester');
    });
  });

  group('ContactList', () {
    test('saves and loads contact lists', () {
      final contacts = ContactList(pubKey: 'pub1', contacts: ['c1', 'c2']);

      store.saveContactList(contacts);

      final loaded = store.loadContactList('pub1');
      expect(loaded, isNotNull);
      expect(loaded!.pubKey, 'pub1');
      expect(loaded.contacts, ['c1', 'c2']);
    });
  });

  group('UserRelayList', () {
    test('saves and loads user relay lists', () {
      final relays = UserRelayList(
        pubKey: 'pub1',
        relays: {
          'wss://relay1.com': ReadWriteMarker.from(read: true, write: false),
        },
        createdAt: 1000,
        refreshedTimestamp: 2000,
      );

      store.saveUserRelayList(relays);

      final loaded = store.loadUserRelayList('pub1');
      expect(loaded, isNotNull);
      expect(loaded!.pubKey, 'pub1');
      expect(loaded.relays.keys, contains('wss://relay1.com'));
    });
  });
}
