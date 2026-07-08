import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:ndk/ndk.dart';
import 'package:ndk/domain_layer/entities/read_write_marker.dart';
import 'package:ndk/domain_layer/entities/contact_list.dart' as ndk_contacts;
import 'package:ndk/domain_layer/entities/user_relay_list.dart';
import 'package:zapbook/core/config/zapbook_config.dart';

import 'package:zapbook/core/data/cache/nostr_cache_store.dart';

@lazySingleton
class NostrService {
  NostrService(this._ndk, this._store);

  final Ndk _ndk;
  final NostrCacheStore _store;
  final _log = logging.Logger('NostrService');

  bool get isLoggedIn => _ndk.accounts.isLoggedIn;
  String? get pubkey => _ndk.accounts.getPublicKey();

  Future<ndk_contacts.ContactList?> getContactList(String pubkey) =>
      _ndk.follows.getContactList(pubkey);

  Future<ndk_contacts.ContactList> broadcastAddContact(String hex) =>
      _ndk.follows.broadcastAddContact(hex);

  Future<ndk_contacts.ContactList?> broadcastRemoveContact(String hex) =>
      _ndk.follows.broadcastRemoveContact(hex);

  Future<Metadata> publishMetadata({
    String? name,
    String? displayName,
    String? lud16,
    String? about,
    String? picture,
    String? banner,
    String? website,
    String? nip05,
  }) async {
    final pubKey = _ndk.accounts.getPublicKey();
    if (pubKey == null) {
      throw StateError('No logged-in account. Sign in before publishing.');
    }

    final metadata = Metadata(
      pubKey: pubKey,
      name: name,
      displayName: displayName,
      lud16: lud16,
      about: about,
      picture: picture,
      banner: banner,
      website: website,
      nip05: nip05,
    );

    return _ndk.metadata.broadcastMetadata(
      metadata,
      specificRelays: ZapbookConfig.broadcastRelays,
    );
  }

  Future<void> ensureRelayListPublished() async {
    final pubKey = _ndk.accounts.getPublicKey();
    if (pubKey == null) return;

    try {
      final existing = await _ndk.userRelayLists.getSingleUserRelayList(pubKey);
      if (existing != null && existing.relays.isNotEmpty) return;

      await _ndk.userRelayLists.setInitialUserRelayList(
        UserRelayList(
          pubKey: pubKey,
          relays: {
            for (final url in ZapbookConfig.broadcastRelays)
              url: ReadWriteMarker.readWrite,
          },
          createdAt: 0,
          refreshedTimestamp: 0,
        ),
      );
      _log.info('Published NIP-65 relay list');
    } on Object catch (error, stack) {
      _log.warning('ensureRelayListPublished failed', error, stack);
    }
  }

  Future<Metadata?> getMetadata(String pubkey, {bool forceRefresh = false}) =>
      _ndk.metadata.loadMetadata(pubkey, forceRefresh: forceRefresh);

  ndk_contacts.ContactList? getCachedContactList(String pubkey) =>
      _store.loadContactList(pubkey);

  List<Metadata> getCachedMetadatas(List<String> pubkeys) =>
      _store.loadMetadatas(pubkeys);

  List<Metadata> getCachedMetadatasFromEvents(List<String> pubkeys) {
    if (pubkeys.isEmpty) return const [];
    final events = _store.loadEvents(
      kinds: const [Metadata.kKind],
      pubKeys: pubkeys,
    );
    final metadatas = <Metadata>[];
    for (final event in events) {
      try {
        metadatas.add(Metadata.fromEvent(event));
      } catch (_) {
        _log.warning('Failed to parse metadata from event: ${event.id}');
      }
    }
    return metadatas;
  }

  Future<List<Metadata>> getMetadatas(
    List<String> pubkeys, {
    RelaySet? relaySet,
    void Function(Metadata)? onLoad,
  }) => _ndk.metadata.loadMetadatas(pubkeys, relaySet, onLoad: onLoad);

  NdkResponse subscribeMetadata(List<String> pubkeys) =>
      _ndk.requests.subscription(
        cacheWrite: true,
        filter: Filter(kinds: const [Metadata.kKind], authors: pubkeys),
      );

  void saveMetadata(Metadata meta) => _store.saveMetadata(meta);

  void closeSubscription(String requestId) =>
      _ndk.requests.closeSubscription(requestId);

  Future<void> dispose() => _ndk.destroy();
}
