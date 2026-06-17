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
  final _npubByHex = <String, String>{};

  final _permanentHexes = <String>{};
  final _transientHexesCount = <String, int>{};
  final _activeSubscriptionHexes = <String>{};

  final _contactCache = <String, Contact>{};

  final _metaTick = StreamController<void>.broadcast();
  NdkResponse? _metaSub;
  StreamSubscription<Nip01Event>? _metaListen;
  Timer? _tickTimer;

  bool _initialized = false;
  final _storedContacts = <String>{};
  final _storedContactsList = <String>[];

  void _ensureInitialized() {
    if (_initialized) return;
    final list = _prefs.getStringList(_key) ?? const [];
    _storedContacts.addAll(list);
    _storedContactsList.addAll(list);
    _initialized = true;
  }

  bool isValidNpub(String value) => Nip19.isPubkey(value.trim());

  bool contains(String npub) {
    _ensureInitialized();
    return _storedContacts.contains(npub);
  }

  List<String> get stored {
    _ensureInitialized();
    return List.unmodifiable(_storedContactsList);
  }

  Stream<void> get metadataChanges => _metaTick.stream;

  Stream<List<Contact>> get friendsStream =>
      _metaTick.stream.map((_) => _currentFriends());

  Stream<List<Contact>> watch(List<String> npubs) async* {
    List<String> hexes = [];
    try {
      final futures = npubs.map((npub) async {
        try {
          return await _hexOf(npub);
        } on ContactException catch (error, trace) {
          _log.info('Watching npub $error', trace);
          return '';
        }
      });
      final results = await Future.wait(futures);
      hexes = results.where((h) => h.isNotEmpty).toList();

      for (final hex in hexes) {
        _transientHexesCount[hex] = (_transientHexesCount[hex] ?? 0) + 1;
      }
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
    } finally {
      for (final hex in hexes) {
        final count = _transientHexesCount[hex] ?? 0;
        if (count <= 1) {
          _transientHexesCount.remove(hex);
        } else {
          _transientHexesCount[hex] = count - 1;
        }
      }
      _subscribe();
    }
  }

  Future<void> warm() async {
    try {
      _ensureInitialized();
      await friends();
    } on Exception catch (e, stack) {
      _log.warning('Warm contact service failed', e, stack);
    }
  }

  Future<List<Contact>> friends() async {
    _ensureInitialized();
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
    if (cached != null) return _contact(npub);
    final meta = await _nostr.getMetadata(hex);
    if (meta != null) _store(meta);
    return _contact(npub);
  }

  Future<void> prime(List<String> npubs) async {
    final futures = npubs.map((npub) async {
      try {
        return await _hexOf(npub);
      } on ContactException {
        return '';
      }
    });
    final results = await Future.wait(futures);
    final hexes = results.where((h) => h.isNotEmpty).toList();

    if (hexes.isEmpty) return;

    _permanentHexes.addAll(hexes);
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

  Contact contactFor(String npub) => _contact(npub);

  Future<Contact> add(String npub) async {
    _ensureInitialized();
    final myNpub = await _identity.readNpub();
    if (npub == myNpub) {
      throw ContactException('Cannot add yourself as a contact');
    }
    final hex = await _hexOf(npub);
    final meta = await _nostr.getMetadata(hex, forceRefresh: true);
    if (meta != null) _store(meta);

    if (!_storedContacts.contains(npub)) {
      _storedContacts.add(npub);
      _storedContactsList.add(npub);
      await _prefs.setStringList(_key, _storedContactsList);
    }
    await _ensureHexMap();
    _tick();
    return _contact(npub);
  }

  Future<void> remove(String npub) async {
    _ensureInitialized();
    if (_storedContacts.contains(npub)) {
      _storedContacts.remove(npub);
      _storedContactsList.remove(npub);
      await _prefs.setStringList(_key, _storedContactsList);
    }

    await _ensureHexMap();
    _tick();
  }

  Future<List<String>> _ensureHexMap() async {
    final myNpub = await _identity.readNpub();
    final filtered = _storedContactsList.where((n) => n != myNpub).toList();

    final missingNpubs = filtered
        .where((n) => !_hexByNpub.containsKey(n))
        .toList();
    if (missingNpubs.isNotEmpty) {
      final futures = missingNpubs.map((npub) async {
        try {
          return await _hexOf(npub);
        } on ContactException {
          return '';
        }
      });
      await Future.wait(futures);
    }

    _permanentHexes.clear();
    for (final n in filtered) {
      final hex = _hexByNpub[n];
      if (hex != null) _permanentHexes.add(hex);
    }
    _subscribe();
    return filtered;
  }

  void _subscribe() {
    final allHexes = _permanentHexes.union(_transientHexesCount.keys.toSet());
    if (allHexes.isEmpty) return;

    if (allHexes.length == _activeSubscriptionHexes.length &&
        allHexes.containsAll(_activeSubscriptionHexes)) {
      return;
    }

    _activeSubscriptionHexes.clear();
    _activeSubscriptionHexes.addAll(allHexes);

    final old = _metaSub;
    if (old != null) _nostr.closeSubscription(old.requestId);
    unawaited(_metaListen?.cancel());

    final response = _nostr.subscribeMetadata(allHexes.toList());
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

      final npub = _npubByHex[meta.pubKey];
      if (npub != null) {
        _contactCache.remove(npub);
      }
    }
  }

  Future<String> _hexOf(String npub) async {
    final cached = _hexByNpub[npub];
    if (cached != null) return cached;
    try {
      final hex = await MarmotIdentity.pubkeyHexFromNpub(npub);
      _hexByNpub[npub] = hex;
      _npubByHex[hex] = npub;
      return hex;
    } on Object {
      throw ContactException('Invalid npub format');
    }
  }

  List<Contact> _buildContacts(List<String> npubs) => [
    for (final npub in npubs) _contact(npub),
  ];

  List<Contact> _currentFriends() {
    _ensureInitialized();
    return _buildContacts(
      _storedContactsList.where(_hexByNpub.containsKey).toList(),
    );
  }

  void _tick() {
    if (_metaTick.isClosed) return;
    if (_tickTimer?.isActive ?? false) return;

    _tickTimer = Timer(const Duration(milliseconds: 100), () {
      if (!_metaTick.isClosed) _metaTick.add(null);
    });
  }

  Contact _contact(String npub) {
    var cached = _contactCache[npub];
    if (cached != null) return cached;

    final hex = _hexByNpub[npub];
    final meta = hex != null ? _metaByHex[hex] : null;

    final name = (meta?.displayName?.trim().isNotEmpty ?? false)
        ? meta!.displayName
        : meta?.name;

    cached = Contact(
      npub: npub,
      displayName: name,
      picture: meta?.picture,
      lud16: meta?.lud16,
    );
    _contactCache[npub] = cached;
    return cached;
  }

  @disposeMethod
  void dispose() {
    _tickTimer?.cancel();
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
