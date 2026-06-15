import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:ndk/ndk.dart';
import 'package:ndk/domain_layer/entities/read_write_marker.dart';
import 'package:ndk/domain_layer/entities/user_relay_list.dart';

@lazySingleton
class NostrService {
  NostrService(this._ndk);

  final Ndk _ndk;
  final _log = logging.Logger('NostrService');

  static const List<String> broadcastRelays = [
    'wss://relay.damus.io',
    'wss://nos.lol',
    'wss://relay.primal.net',
  ];

  bool get isLoggedIn => _ndk.accounts.isLoggedIn;
  String? get pubkey => _ndk.accounts.getPublicKey();

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
      specificRelays: broadcastRelays,
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
            for (final url in broadcastRelays) url: ReadWriteMarker.readWrite,
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

  void closeSubscription(String requestId) =>
      _ndk.requests.closeSubscription(requestId);

  Future<void> dispose() => _ndk.destroy();
}
