import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:ndk/ndk.dart';
import 'package:logging/logging.dart' as logging;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/core/identity/active_account.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/nostr_service.dart';

@lazySingleton
class ContactService {
  ContactService(this._prefs, this._nostr, this._identity);

  final SharedPreferences _prefs;
  final NostrService _nostr;
  final IdentityLocalDataSource _identity;

  static String get _key => ActiveAccount.key('contacts.npubs');
  final _log = logging.Logger('ContactService');

  final _metaByHex = <String, Metadata>{};
  final _hexByNpub = <String, String>{};
  final _subscribedHexes = <String>{};
  final _metaTick = StreamController<void>.broadcast();
  NdkResponse? _metaSub;
  StreamSubscription<Nip01Event>? _metaListen;
  String _subKey = '';

  bool isValidNpub(String value) => Nip19.isPubkey(value.trim());

  bool contains(String npub) => _stored().contains(npub);

  List<String> get stored => List.unmodifiable(_stored());

  Stream<void> get metadataChanges => _metaTick.stream;

  Stream<List<Contact>> get friendsStream =>
      _metaTick.stream.map((_) => _currentFriends());

  Stream<List<Contact>> watch(List<String> npubs) async* {
    final hexes = <String>[];
    for (final npub in npubs) {
      try {
        hexes.add(await _hexOf(npub));
      } on ContactException {
        // skip invalid npub
      }
    }
    _subscribedHexes.addAll(hexes);
    _subscribe();
    yield _buildContacts(npubs);

    final missing = hexes.where((h) => !_metaByHex.containsKey(h)).toList();
    if (missing.isNotEmpty) {
      try {
        for (final meta in await _nostr.getMetadatas(missing)) {
          _store(meta);
        }
      } on Object catch (e, stack) {
        _log.info('watch metadatas $e', stack);
      }
      yield _buildContacts(npubs);
    }
    yield* _metaTick.stream.map((_) => _buildContacts(npubs));
  }

  Future<void> warm() async {
    try {
      await friends();
    } on Exception catch (e, stack) {
      _log.warning('Warm contact service failed', e, stack);
    }
  }

  List<String> _stored() => _prefs.getStringList(_key) ?? const [];

  Future<List<Contact>> friends() async {
    final filtered = await _ensureHexMap();
    if (filtered.isEmpty) return const [];

    final hexes = [for (final n in filtered) _hexByNpub[n]!];
    for (final meta in await _nostr.getMetadatas(hexes)) {
      _store(meta);
    }
    _tick();
    return _buildContacts(filtered);
  }

  Future<Contact> resolve(String npub) async {
    final hex = await _hexOf(npub);
    final cached = _metaByHex[hex];
    if (cached != null) return _contact(npub, cached);
    final meta = await _nostr.getMetadata(hex);
    if (meta != null) _store(meta);
    return _contact(npub, _metaByHex[hex]);
  }

  Future<void> prime(List<String> npubs) async {
    final hexes = <String>[];
    for (final npub in npubs) {
      try {
        hexes.add(await _hexOf(npub));
      } on ContactException {
        // skip invalid npub
      }
    }
    if (hexes.isEmpty) return;
    _subscribedHexes.addAll(hexes);
    _subscribe();
    final missing = hexes.where((h) => !_metaByHex.containsKey(h)).toList();
    if (missing.isNotEmpty) {
      try {
        for (final meta in await _nostr.getMetadatas(missing)) {
          _store(meta);
        }
      } on Object catch (e, stack) {
        _log.info('prime $e', stack);
      }
    }
  }

  Contact contactFor(String npub) =>
      _contact(npub, _metaByHex[_hexByNpub[npub]]);

  Future<Contact> add(String npub) async {
    final myNpub = await _identity.readNpub();
    if (npub == myNpub) {
      throw ContactException('Cannot add yourself as a contact');
    }
    final hex = await _hexOf(npub);
    final meta = await _nostr.getMetadata(hex, forceRefresh: true);
    if (meta != null) _store(meta);
    if (!_stored().contains(npub)) {
      await _prefs.setStringList(_key, [..._stored(), npub]);
    }
    await _ensureHexMap();
    _tick();
    return _contact(npub, _metaByHex[hex]);
  }

  Future<void> remove(String npub) async {
    await _prefs.setStringList(
      _key,
      _stored().where((stored) => stored != npub).toList(),
    );
    await _ensureHexMap();
    _tick();
  }

  Future<List<String>> _ensureHexMap() async {
    final myNpub = await _identity.readNpub();
    final filtered = _stored().where((n) => n != myNpub).toList();
    for (final npub in filtered) {
      _hexByNpub[npub] ??= await MarmotIdentity.pubkeyHexFromNpub(npub);
    }
    _subscribedHexes.addAll([for (final n in filtered) _hexByNpub[n]!]);
    _subscribe();
    return filtered;
  }

  void _subscribe() {
    final sorted = _subscribedHexes.toList()..sort();
    if (sorted.isEmpty) return;
    final key = sorted.join(',');
    if (key == _subKey) return;
    _subKey = key;

    final old = _metaSub;
    if (old != null) _nostr.closeSubscription(old.requestId);
    unawaited(_metaListen?.cancel());

    final response = _nostr.subscribeMetadata(sorted);
    _metaSub = response;
    _metaListen = response.stream.listen((event) {
      try {
        _store(Metadata.fromEvent(event));
        _tick();
      } on Object catch (e, stack) {
        _log.info('metadata event $e', stack);
      }
    });
  }

  void _store(Metadata meta) {
    final existing = _metaByHex[meta.pubKey];
    if (existing == null ||
        (existing.updatedAt ?? 0) <= (meta.updatedAt ?? 0)) {
      _metaByHex[meta.pubKey] = meta;
    }
  }

  Future<String> _hexOf(String npub) async {
    final cached = _hexByNpub[npub];
    if (cached != null) return cached;
    try {
      final hex = await MarmotIdentity.pubkeyHexFromNpub(npub);
      _hexByNpub[npub] = hex;
      return hex;
    } on Object {
      throw ContactException('Invalid npub format');
    }
  }

  List<Contact> _buildContacts(List<String> npubs) => [
    for (final npub in npubs) _contact(npub, _metaByHex[_hexByNpub[npub]]),
  ];

  List<Contact> _currentFriends() =>
      _buildContacts(_stored().where(_hexByNpub.containsKey).toList());

  void _tick() {
    if (!_metaTick.isClosed) _metaTick.add(null);
  }

  Contact _contact(String npub, Metadata? meta) {
    final name = (meta?.displayName?.trim().isNotEmpty ?? false)
        ? meta!.displayName
        : meta?.name;
    return Contact(
      npub: npub,
      displayName: name,
      picture: meta?.picture,
      lud16: meta?.lud16,
    );
  }

  @disposeMethod
  void dispose() {
    unawaited(_metaListen?.cancel());
    final sub = _metaSub;
    if (sub != null) _nostr.closeSubscription(sub.requestId);
    unawaited(_metaTick.close());
  }
}

class ContactException implements Exception {
  final String message;
  const ContactException(this.message);
  @override
  String toString() => 'ContactException: $message';
}
