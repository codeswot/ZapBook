import 'package:ndk/domain_layer/entities/contact_list.dart';
import 'package:ndk/domain_layer/entities/filter_fetched_ranges.dart';
import 'package:ndk/domain_layer/entities/metadata.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/domain_layer/entities/nip_05.dart';
import 'package:ndk/domain_layer/entities/relay_set.dart';
import 'package:ndk/domain_layer/entities/user_relay_list.dart';
import 'package:ndk/domain_layer/repositories/cache_manager.dart';

import 'package:zapbook/core/data/cache/nostr_cache_store.dart';

class DriftCacheManager implements CacheManager {
  DriftCacheManager(this._store);

  final NostrCacheStore _store;

  // ── In-memory hot cache ─────────────────────────────────

  final Map<String, UserRelayList> _userRelayLists = {};
  final Map<String, RelaySet> _relaySets = {};
  final Map<String, ContactList> _contactLists = {};
  final Map<String, Metadata> _metadatas = {};
  final Map<String, Nip05> _nip05s = {};
  final Map<String, Nip01Event> _events = {};
  final Map<String, FilterFetchedRangeRecord> _filterFetchedRanges = {};

  bool _closed = false;

  // ── Events ──────────────────────────────────────────────

  @override
  Future<void> saveEvent(Nip01Event event) async {
    _events[event.id] = event;
    _store.saveEvent(event);
  }

  @override
  Future<void> saveEvents(List<Nip01Event> events) async {
    for (final e in events) {
      _events[e.id] = e;
    }
    _store.saveEvents(events);
  }

  @override
  Future<Nip01Event?> loadEvent(String id) async {
    final mem = _events[id];
    if (mem != null) return mem;
    final db = _store.loadEvent(id);
    if (db != null) _events[db.id] = db;
    return db;
  }

  @override
  Future<List<Nip01Event>> loadEvents({
    List<String>? ids,
    List<String>? pubKeys,
    List<int>? kinds,
    Map<String, List<String>>? tags,
    int? since,
    int? until,
    String? search,
    int? limit,
  }) async {
    final mem = _events.values.where((e) {
      if (ids != null && !ids.contains(e.id)) return false;
      if (pubKeys != null && !pubKeys.contains(e.pubKey)) return false;
      if (kinds != null && !kinds.contains(e.kind)) return false;
      if (since != null && e.createdAt < since) return false;
      if (until != null && e.createdAt > until) return false;
      if (search != null &&
          !e.content.toLowerCase().contains(search.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
    if (mem.isNotEmpty) return mem;
    final db = _store.loadEvents(
      ids: ids,
      pubKeys: pubKeys,
      kinds: kinds,
      tags: tags,
      since: since,
      until: until,
      search: search,
      limit: limit,
    );
    for (final e in db) {
      _events[e.id] = e;
    }
    return db;
  }

  @override
  Future<void> removeEvent(String id) async {
    _events.remove(id);
    _store.removeEvent(id);
  }

  @override
  Future<void> removeEvents({
    List<String>? ids,
    List<String>? pubKeys,
    List<int>? kinds,
    Map<String, List<String>>? tags,
    int? since,
    int? until,
  }) async {
    _events.removeWhere((_, e) {
      if (ids != null && !ids.contains(e.id)) return false;
      if (pubKeys != null && !pubKeys.contains(e.pubKey)) return false;
      if (kinds != null && !kinds.contains(e.kind)) return false;
      if (since != null && e.createdAt < since) return false;
      if (until != null && e.createdAt > until) return false;
      return true;
    });
    _store.removeEvents(
      ids: ids,
      pubKeys: pubKeys,
      kinds: kinds,
      tags: tags,
      since: since,
      until: until,
    );
  }

  @override
  Future<void> removeAllEventsByPubKey(String pubKey) async {
    _events.removeWhere((_, e) => e.pubKey == pubKey);
    _store.removeAllEventsByPubKey(pubKey);
  }

  @override
  Future<void> removeAllEvents() async {
    _events.clear();
    _store.removeAllEvents();
  }

  // ── Metadata ────────────────────────────────────────────

  @override
  Future<void> saveMetadata(Metadata metadata) async {
    _metadatas[metadata.pubKey] = metadata;
    _store.saveMetadata(metadata);
  }

  @override
  Future<void> saveMetadatas(List<Metadata> metadatas) async {
    for (final m in metadatas) {
      _metadatas[m.pubKey] = m;
    }
    for (final m in metadatas) {
      _store.saveMetadata(m);
    }
  }

  @override
  Future<Metadata?> loadMetadata(String pubKey) async {
    final mem = _metadatas[pubKey];
    if (mem != null) return mem;
    final db = _store.loadMetadata(pubKey);
    if (db != null) _metadatas[pubKey] = db;
    return db;
  }

  @override
  Future<List<Metadata?>> loadMetadatas(List<String> pubKeys) async {
    final results = <Metadata?>[];
    for (final pk in pubKeys) {
      results.add(await loadMetadata(pk));
    }
    return results;
  }

  @override
  Future<Iterable<Metadata>> searchMetadatas(String search, int limit) async {
    final searchLower = search.toLowerCase();
    final mem = _metadatas.values
        .where((m) {
          final name = (m.name ?? '').toLowerCase();
          final display = (m.displayName ?? '').toLowerCase();
          final nip05 = (m.nip05 ?? '').toLowerCase();
          return name.contains(searchLower) ||
              display.contains(searchLower) ||
              nip05.contains(searchLower);
        })
        .take(limit)
        .toList();
    if (mem.isNotEmpty) return mem;
    return _store.searchMetadatas(search, limit);
  }

  @override
  Future<void> removeMetadata(String pubKey) async {
    _metadatas.remove(pubKey);
    _store.removeMetadata(pubKey);
  }

  @override
  Future<void> removeAllMetadatas() async {
    _metadatas.clear();
    _store.removeAllMetadatas();
  }

  // ── Contact Lists ───────────────────────────────────────

  @override
  Future<void> saveContactList(ContactList contactList) async {
    _contactLists[contactList.pubKey] = contactList;
    _store.saveContactList(contactList);
  }

  @override
  Future<void> saveContactLists(List<ContactList> contactLists) async {
    for (final cl in contactLists) {
      _contactLists[cl.pubKey] = cl;
      _store.saveContactList(cl);
    }
  }

  @override
  Future<ContactList?> loadContactList(String pubKey) async {
    final mem = _contactLists[pubKey];
    if (mem != null) return mem;
    final db = _store.loadContactList(pubKey);
    if (db != null) _contactLists[pubKey] = db;
    return db;
  }

  @override
  Future<void> removeContactList(String pubKey) async {
    _contactLists.remove(pubKey);
    _store.removeContactList(pubKey);
  }

  @override
  Future<void> removeAllContactLists() async {
    _contactLists.clear();
    for (final key in _contactLists.keys.toList()) {
      _store.removeContactList(key);
    }
  }

  // ── User Relay Lists ────────────────────────────────────

  @override
  Future<void> saveUserRelayList(UserRelayList userRelayList) async {
    _userRelayLists[userRelayList.pubKey] = userRelayList;
    _store.saveUserRelayList(userRelayList);
  }

  @override
  Future<void> saveUserRelayLists(List<UserRelayList> userRelayLists) async {
    for (final l in userRelayLists) {
      _userRelayLists[l.pubKey] = l;
      _store.saveUserRelayList(l);
    }
  }

  @override
  Future<UserRelayList?> loadUserRelayList(String pubKey) async {
    final mem = _userRelayLists[pubKey];
    if (mem != null) return mem;
    final db = _store.loadUserRelayList(pubKey);
    if (db != null) _userRelayLists[pubKey] = db;
    return db;
  }

  @override
  Future<void> removeUserRelayList(String pubKey) async {
    _userRelayLists.remove(pubKey);
    _store.removeUserRelayList(pubKey);
  }

  @override
  Future<void> removeAllUserRelayLists() async {
    _userRelayLists.clear();
    for (final key in _userRelayLists.keys.toList()) {
      _store.removeUserRelayList(key);
    }
  }

  // ── Relay Sets ──────────────────────────────────────────

  @override
  Future<RelaySet?> loadRelaySet(String name, String pubKey) async {
    final key = '$pubKey:$name';
    return _relaySets[key];
  }

  @override
  Future<void> saveRelaySet(RelaySet relaySet) async {
    _relaySets['${relaySet.pubKey}:${relaySet.name}'] = relaySet;
  }

  @override
  Future<void> removeRelaySet(String name, String pubKey) async {
    _relaySets.remove('$pubKey:$name');
  }

  @override
  Future<void> removeAllRelaySets() async {
    _relaySets.clear();
  }

  // ── NIP-05 ──────────────────────────────────────────────

  @override
  Future<void> saveNip05(Nip05 nip05) async {
    _nip05s[nip05.pubKey] = nip05;
  }

  @override
  Future<void> saveNip05s(List<Nip05> nip05s) async {
    for (final n in nip05s) {
      _nip05s[n.pubKey] = n;
    }
  }

  @override
  Future<Nip05?> loadNip05({String? pubKey, String? identifier}) async {
    if (pubKey != null) return _nip05s[pubKey];
    return null;
  }

  @override
  Future<List<Nip05?>> loadNip05s(List<String> pubKeys) async {
    return pubKeys.map((pk) => _nip05s[pk]).toList();
  }

  @override
  Future<void> removeNip05(String pubKey) async {
    _nip05s.remove(pubKey);
  }

  @override
  Future<void> removeAllNip05s() async {
    _nip05s.clear();
  }

  // ── Filter Fetched Ranges ───────────────────────────────

  @override
  Future<void> saveFilterFetchedRangeRecord(
    FilterFetchedRangeRecord record,
  ) async {}

  @override
  Future<void> saveFilterFetchedRangeRecords(
    List<FilterFetchedRangeRecord> records,
  ) async {}

  @override
  Future<List<FilterFetchedRangeRecord>> loadFilterFetchedRangeRecords(
    String filterHash,
  ) async => [];

  @override
  Future<List<FilterFetchedRangeRecord>> loadFilterFetchedRangeRecordsByRelay(
    String filterHash,
    String relayUrl,
  ) async => [];

  @override
  Future<List<FilterFetchedRangeRecord>>
  loadFilterFetchedRangeRecordsByRelayUrl(String relayUrl) async => [];

  @override
  Future<void> removeFilterFetchedRangeRecords(String filterHash) async {}

  @override
  Future<void> removeFilterFetchedRangeRecordsByFilterAndRelay(
    String filterHash,
    String relayUrl,
  ) async {}

  @override
  Future<void> removeFilterFetchedRangeRecordsByRelay(String relayUrl) async {}

  @override
  Future<void> removeAllFilterFetchedRangeRecords() async {}

  // ── Deprecated ──────────────────────────────────────────

  @override
  Future<Iterable<Nip01Event>> searchEvents({
    List<String>? ids,
    List<String>? authors,
    List<int>? kinds,
    Map<String, List<String>>? tags,
    int? since,
    int? until,
    String? search,
    int limit = 100,
  }) async => [];

  // ── Maintenance ─────────────────────────────────────────

  @override
  Future<void> clearAll() async {
    _events.clear();
    _metadatas.clear();
    _contactLists.clear();
    _userRelayLists.clear();
    _relaySets.clear();
    _nip05s.clear();
    _filterFetchedRanges.clear();
    _store.clearAll();
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _store.closeStore();
  }
}
