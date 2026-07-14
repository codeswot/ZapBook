import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:ndk/ndk.dart';
import 'package:logging/logging.dart' as logging;

import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/data/infrastructure/nostr_service.dart';

@lazySingleton
class ContactService {
  ContactService(this._nostr, this._identity);

  final NostrService _nostr;
  final IdentityLocalDataSource _identity;
  final _log = logging.Logger('ContactService');

  final _friendsController = StreamController<List<Contact>>.broadcast();
  List<Contact> _currentFriends = [];

  bool isValidNpub(String value) => Nip19.isPubkey(value.trim());

  Stream<List<Contact>> get friends {
    _loadFriends();
    return _friendsController.stream;
  }

  Future<void> _loadFriends() async {
    final pubkey = _nostr.pubkey;
    if (pubkey == null) return;

    final cachedList = _nostr.getCachedContactList(pubkey);
    if (cachedList != null) {
      final hexes = List<String>.from(
        cachedList.contacts,
      ).where((h) => h.length == 64).toList();
      if (hexes.isNotEmpty) {
        var metas = _nostr.getCachedMetadatas(hexes);
        if (metas.isEmpty) {
          metas = _nostr.getCachedMetadatasFromEvents(hexes);
        }
        _currentFriends = _buildContacts(hexes, metas);
        _friendsController.add(_currentFriends);
      } else {
        _currentFriends = [];
        _friendsController.add(_currentFriends);
      }
    }

    try {
      final contactList = await _nostr.getContactList(pubkey);
      if (contactList == null) {
        if (cachedList == null) {
          _currentFriends = [];
          _friendsController.add(_currentFriends);
        }
        return;
      }

      final hexes = List<String>.from(
        contactList.contacts,
      ).where((h) => h.length == 64).toList();
      if (hexes.isEmpty) {
        _currentFriends = [];
        _friendsController.add(_currentFriends);
        return;
      }

      final metas = await _nostr.getMetadatas(hexes);
      _currentFriends = _buildContacts(hexes, metas);
      _friendsController.add(_currentFriends);
    } catch (e, stack) {
      _log.warning('Failed network friends sync', e, stack);
    }
  }

  Future<Contact> resolve(String npub, {bool forceRefresh = false}) async {
    final hex = await _hexOf(npub);
    final meta =
        _nostr.getCachedMetadatas([hex]).firstOrNull ??
        _nostr.getCachedMetadatasFromEvents([hex]).firstOrNull ??
        await _nostr.getMetadata(hex, forceRefresh: forceRefresh);

    return _contact(hex, npub, meta);
  }

  Future<Contact> add(String npub) async {
    final myNpub = await _identity.readNpub();
    if (npub == myNpub) {
      throw const ContactException('Cannot add yourself as a contact');
    }

    final hex = await _hexOf(npub);
    final meta = await _nostr.getMetadata(hex);

    if (_nostr.pubkey != null) {
      await _nostr.broadcastAddContact(hex);
      _loadFriends();
    }

    return _contact(hex, npub, meta);
  }

  Future<void> remove(String npub) async {
    final hex = await _hexOf(npub);
    if (_nostr.pubkey != null) {
      await _nostr.broadcastRemoveContact(hex);
      _loadFriends();
    }
  }

  Future<void> prime(List<String> npubs) async {
    final futures = npubs.map((npub) async {
      try {
        final hex = await _hexOf(npub);
        if (hex.isNotEmpty) {
          await _nostr.getMetadata(hex);
        }
      } catch (_) {}
    });
    await Future.wait(futures);
  }

  Contact contactFor(String npub) {
    String hex;
    try {
      hex = Nip19.decode(npub);
    } catch (_) {
      hex = '';
      _log.warning('Invalid npub format: $npub');
    }

    Metadata? meta;
    if (hex.isNotEmpty) {
      final metas = _nostr.getCachedMetadatas([hex]);
      if (metas.isNotEmpty) {
        meta = metas.first;
      } else {
        final eventsMeta = _nostr.getCachedMetadatasFromEvents([hex]);
        if (eventsMeta.isNotEmpty) {
          meta = eventsMeta.first;
        }
      }
    }

    return _contact(hex, npub, meta);
  }

  Future<String> _hexOf(String npub) async {
    try {
      return Nip19.decode(npub);
    } catch (_) {
      try {
        return await MarmotIdentity.pubkeyHexFromNpub(npub);
      } catch (_) {
        throw const ContactException('Invalid npub format');
      }
    }
  }

  List<Contact> _buildContacts(List<String> hexes, List<Metadata> metas) {
    final metaMap = {for (final m in metas) m.pubKey: m};
    return hexes
        .map((hex) => _contact(hex, Nip19.encodePubKey(hex), metaMap[hex]))
        .toList();
  }

  Contact _contact(String hex, String npub, Metadata? meta) {
    final name = (meta?.displayName?.trim().isNotEmpty ?? false)
        ? meta!.displayName
        : meta?.name;

    final pubkey = _nostr.pubkey;
    bool isFollow = false;
    if (pubkey != null) {
      final cachedList = _nostr.getCachedContactList(pubkey);
      if (cachedList != null) {
        isFollow = cachedList.contacts.contains(hex);
      }
    }

    return Contact(
      npub: npub,
      displayName: name,
      picture: meta?.picture,
      lud16: meta?.lud16,
      isFollow: isFollow,
    );
  }

  @disposeMethod
  void dispose() {
    _friendsController.close();
  }
}

class ContactException implements Exception {
  final String message;
  const ContactException(this.message);
  @override
  String toString() => 'ContactException: $message';
}
