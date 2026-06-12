import 'package:injectable/injectable.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:ndk/ndk.dart';
import 'package:logging/logging.dart' as logging;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/nostr_service.dart';

@lazySingleton
class ContactService {
  ContactService(this._prefs, this._nostr, this._identity);

  final SharedPreferences _prefs;
  final NostrService _nostr;
  final IdentityLocalDataSource _identity;

  static const _key = 'contacts.npubs';
  final _log = logging.Logger('ContactService');

  bool isValidNpub(String value) => Nip19.isPubkey(value.trim());

  bool contains(String npub) => _stored().contains(npub);

  List<String> get stored => List.unmodifiable(_stored());

  Future<void> warm() async {
    try {
      await friends();
    } on Exception catch (e, stack) {
      _log.warning('Warm contact service failed', e, stack);
    }
  }

  List<String> _stored() => _prefs.getStringList(_key) ?? const [];

  Future<List<Contact>> friends() async {
    final npubs = _stored();
    final myNpub = await _identity.readNpub();
    final filtered = npubs.where((n) => n != myNpub).toList();
    if (filtered.isEmpty) return const [];

    final hexes = await Future.wait(
      filtered.map(MarmotIdentity.pubkeyHexFromNpub),
    );
    final hexByNpub = {
      for (var i = 0; i < filtered.length; i++) filtered[i]: hexes[i],
    };
    final metas = await _nostr.getMetadatas(hexByNpub.values.toList());
    final metaByHex = {for (final meta in metas) meta.pubKey: meta};

    return [
      for (final npub in filtered) _contact(npub, metaByHex[hexByNpub[npub]]),
    ];
  }

  Future<Contact> resolve(String npub) async {
    String hex;
    try {
      hex = await MarmotIdentity.pubkeyHexFromNpub(npub);
    } on Object {
      throw ContactException('Invalid npub format');
    }
    final meta = await _nostr.getMetadata(hex);
    return _contact(npub, meta);
  }

  Future<Contact> add(String npub) async {
    final myNpub = await _identity.readNpub();
    if (npub == myNpub) {
      throw ContactException('Cannot add yourself as a contact');
    }
    final contact = await resolve(npub);
    if (!_stored().contains(npub)) {
      await _prefs.setStringList(_key, [..._stored(), npub]);
    }
    return contact;
  }

  Future<void> remove(String npub) async {
    await _prefs.setStringList(
      _key,
      _stored().where((stored) => stored != npub).toList(),
    );
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
}

class ContactException implements Exception {
  final String message;
  const ContactException(this.message);
  @override
  String toString() => 'ContactException: $message';
}
