import 'dart:convert';

import 'package:ndk/domain_layer/entities/contact_list.dart';
import 'package:ndk/domain_layer/entities/metadata.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/domain_layer/entities/read_write_marker.dart';
import 'package:ndk/domain_layer/entities/user_relay_list.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

class NostrCacheStore {
  NostrCacheStore._(this._db);

  final Database _db;

  static Future<NostrCacheStore> open() async {
    final dir = await getApplicationSupportDirectory();
    final dbPath = '${dir.path}/nostr_cache.db';
    final db = sqlite3.open(dbPath);

    db.execute('''
      CREATE TABLE IF NOT EXISTS events (
        id TEXT PRIMARY KEY,
        pub_key TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        kind INTEGER NOT NULL,
        content TEXT NOT NULL,
        sig TEXT,
        tags TEXT NOT NULL,
        sources TEXT NOT NULL
      )
    ''');
    db.execute(
        'CREATE INDEX IF NOT EXISTS idx_events_pub_key ON events(pub_key)');
    db.execute('CREATE INDEX IF NOT EXISTS idx_events_kind ON events(kind)');
    db.execute(
        'CREATE INDEX IF NOT EXISTS idx_events_created_at ON events(created_at)');

    db.execute('''
      CREATE TABLE IF NOT EXISTS metadatas (
        pub_key TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        updated_at INTEGER,
        refreshed_at INTEGER
      )
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS contact_lists (
        pub_key TEXT PRIMARY KEY,
        contacts TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS user_relay_lists (
        pub_key TEXT PRIMARY KEY,
        relays TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        refreshed_at INTEGER NOT NULL
      )
    ''');

    return NostrCacheStore._(db);
  }

  // ── Events ──────────────────────────────────────────────

  void saveEvent(Nip01Event event) {
    final stmt = _db.prepare(
        'INSERT OR REPLACE INTO events (id, pub_key, created_at, kind, content, sig, tags, sources) VALUES (?, ?, ?, ?, ?, ?, ?, ?)');
    stmt.execute([
      event.id,
      event.pubKey,
      event.createdAt,
      event.kind,
      event.content,
      event.sig,
      jsonEncode(event.tags),
      jsonEncode(event.sources),
    ]);
    stmt.close();
  }

  void saveEvents(List<Nip01Event> events) {
    for (final e in events) {
      saveEvent(e);
    }
  }

  Nip01Event? loadEvent(String id) {
    final result = _db.select('SELECT * FROM events WHERE id = ?', [id]);
    if (result.isEmpty) return null;
    return _rowToEvent(result.first);
  }

  List<Nip01Event> loadEvents({
    List<String>? ids,
    List<String>? pubKeys,
    List<int>? kinds,
    Map<String, List<String>>? tags,
    int? since,
    int? until,
    String? search,
    int? limit,
  }) {
    final conditions = <String>[];
    final params = <Object?>[];

    if (ids != null && ids.isNotEmpty) {
      conditions.add('id IN (${ids.map((_) => '?').join(',')})');
      params.addAll(ids);
    }
    if (pubKeys != null && pubKeys.isNotEmpty) {
      conditions.add('pub_key IN (${pubKeys.map((_) => '?').join(',')})');
      params.addAll(pubKeys);
    }
    if (kinds != null && kinds.isNotEmpty) {
      conditions.add('kind IN (${kinds.map((_) => '?').join(',')})');
      params.addAll(kinds);
    }
    if (since != null) {
      conditions.add('created_at >= ?');
      params.add(since);
    }
    if (until != null) {
      conditions.add('created_at <= ?');
      params.add(until);
    }
    if (search != null && search.isNotEmpty) {
      conditions.add('content LIKE ?');
      params.add('%$search%');
    }

    var query = 'SELECT * FROM events';
    if (conditions.isNotEmpty) {
      query += ' WHERE ${conditions.join(' AND ')}';
    }
    query += ' ORDER BY created_at DESC';
    if (limit != null) {
      query += ' LIMIT ?';
      params.add(limit);
    }

    final result = _db.select(query, params);
    return result.map(_rowToEvent).toList();
  }

  void removeEvent(String id) {
    _db.execute('DELETE FROM events WHERE id = ?', [id]);
  }

  void removeEvents({
    List<String>? ids,
    List<String>? pubKeys,
    List<int>? kinds,
    Map<String, List<String>>? tags,
    int? since,
    int? until,
  }) {
    final conditions = <String>[];
    final params = <Object?>[];

    if (ids != null && ids.isNotEmpty) {
      conditions.add('id IN (${ids.map((_) => '?').join(',')})');
      params.addAll(ids);
    }
    if (pubKeys != null && pubKeys.isNotEmpty) {
      conditions.add('pub_key IN (${pubKeys.map((_) => '?').join(',')})');
      params.addAll(pubKeys);
    }
    if (kinds != null && kinds.isNotEmpty) {
      conditions.add('kind IN (${kinds.map((_) => '?').join(',')})');
      params.addAll(kinds);
    }
    if (since != null) {
      conditions.add('created_at >= ?');
      params.add(since);
    }
    if (until != null) {
      conditions.add('created_at <= ?');
      params.add(until);
    }

    if (conditions.isEmpty) return;

    _db.execute('DELETE FROM events WHERE ${conditions.join(' AND ')}', params);
  }

  void removeAllEventsByPubKey(String pubKey) {
    _db.execute('DELETE FROM events WHERE pub_key = ?', [pubKey]);
  }

  void removeAllEvents() {
    _db.execute('DELETE FROM events');
  }

  Nip01Event _rowToEvent(Row row) {
    return Nip01Event(
      id: row['id'] as String,
      pubKey: row['pub_key'] as String,
      createdAt: row['created_at'] as int,
      kind: row['kind'] as int,
      content: row['content'] as String,
      sig: row['sig'] as String?,
      tags: (jsonDecode(row['tags'] as String) as List)
          .map((t) => (t as List).map((e) => e as String).toList())
          .toList(),
      sources: (jsonDecode(row['sources'] as String) as List)
          .map((e) => e as String)
          .toList(),
    );
  }

  // ── Metadata ────────────────────────────────────────────

  void saveMetadata(Metadata metadata) {
    final stmt = _db.prepare(
        'INSERT OR REPLACE INTO metadatas (pub_key, content, updated_at, refreshed_at) VALUES (?, ?, ?, ?)');
    stmt.execute([
      metadata.pubKey,
      jsonEncode(metadata.toJson()),
      metadata.updatedAt,
      metadata.refreshedTimestamp,
    ]);
    stmt.close();
  }

  Metadata? loadMetadata(String pubKey) {
    final result =
        _db.select('SELECT * FROM metadatas WHERE pub_key = ?', [pubKey]);
    if (result.isEmpty) return null;
    final row = result.first;
    final meta = Metadata.fromJson(
        jsonDecode(row['content'] as String) as Map<String, dynamic>);
    meta.pubKey = row['pub_key'] as String;
    meta.updatedAt = row['updated_at'] as int?;
    meta.refreshedTimestamp = row['refreshed_at'] as int?;
    return meta;
  }

  List<Metadata> searchMetadatas(String search, int limit) {
    final result = _db.select(
      'SELECT * FROM metadatas WHERE content LIKE ? LIMIT ?',
      ['%$search%', limit],
    );
    return result.map((row) {
      final meta = Metadata.fromJson(
          jsonDecode(row['content'] as String) as Map<String, dynamic>);
      meta.pubKey = row['pub_key'] as String;
      meta.updatedAt = row['updated_at'] as int?;
      meta.refreshedTimestamp = row['refreshed_at'] as int?;
      return meta;
    }).toList();
  }

  void removeMetadata(String pubKey) {
    _db.execute('DELETE FROM metadatas WHERE pub_key = ?', [pubKey]);
  }

  void removeAllMetadatas() {
    _db.execute('DELETE FROM metadatas');
  }

  // ── Contact Lists ───────────────────────────────────────

  void saveContactList(ContactList cl) {
    final stmt = _db.prepare(
        'INSERT OR REPLACE INTO contact_lists (pub_key, contacts, created_at) VALUES (?, ?, ?)');
    stmt.execute([
      cl.pubKey,
      jsonEncode(cl.contacts),
      cl.createdAt,
    ]);
    stmt.close();
  }

  ContactList? loadContactList(String pubKey) {
    final result =
        _db.select('SELECT * FROM contact_lists WHERE pub_key = ?', [pubKey]);
    if (result.isEmpty) return null;
    final row = result.first;
    return ContactList(
      pubKey: row['pub_key'] as String,
      contacts: (jsonDecode(row['contacts'] as String) as List)
          .map((e) => e as String)
          .toList(),
    );
  }

  void removeContactList(String pubKey) {
    _db.execute('DELETE FROM contact_lists WHERE pub_key = ?', [pubKey]);
  }

  // ── User Relay Lists ────────────────────────────────────

  void saveUserRelayList(UserRelayList list) {
    final stmt = _db.prepare(
        'INSERT OR REPLACE INTO user_relay_lists (pub_key, relays, created_at, refreshed_at) VALUES (?, ?, ?, ?)');
    final relaysJson = <String, Map<String, dynamic>>{};
    for (final entry in list.relays.entries) {
      relaysJson[entry.key] = {
        'read': entry.value.isRead,
        'write': entry.value.isWrite,
      };
    }
    stmt.execute([
      list.pubKey,
      jsonEncode(relaysJson),
      list.createdAt,
      list.refreshedTimestamp,
    ]);
    stmt.close();
  }

  UserRelayList? loadUserRelayList(String pubKey) {
    final result = _db
        .select('SELECT * FROM user_relay_lists WHERE pub_key = ?', [pubKey]);
    if (result.isEmpty) return null;
    final row = result.first;
    final relaysJson =
        jsonDecode(row['relays'] as String) as Map<String, dynamic>;
    final relays = <String, ReadWriteMarker>{};
    for (final entry in relaysJson.entries) {
      final v = entry.value as Map<String, dynamic>;
      relays[entry.key] =
          ReadWriteMarker.from(read: v['read'] as bool, write: v['write'] as bool);
    }
    return UserRelayList(
      pubKey: row['pub_key'] as String,
      relays: relays,
      createdAt: row['created_at'] as int,
      refreshedTimestamp: row['refreshed_at'] as int,
    );
  }

  void removeUserRelayList(String pubKey) {
    _db.execute('DELETE FROM user_relay_lists WHERE pub_key = ?', [pubKey]);
  }

  // ── Maintenance ─────────────────────────────────────────

  void clearAll() {
    _db.execute('DELETE FROM events');
    _db.execute('DELETE FROM metadatas');
    _db.execute('DELETE FROM contact_lists');
    _db.execute('DELETE FROM user_relay_lists');
  }

  void closeStore() {
    _db.close();
  }
}
