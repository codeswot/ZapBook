import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart';

@lazySingleton
class NostrService {
  NostrService(this._ndk);

  final Ndk _ndk;

  bool _initialized = false;

  bool get isInitialized => _initialized;
  bool get isLoggedIn => _ndk.accounts.isLoggedIn;
  String? get pubkey => _ndk.accounts.getPublicKey();

  void initialize({required String nsec, required String npub}) {
    if (_initialized) return;

    final hexPrivkey = Nip19.decode(nsec);
    final hexPubkey = Nip19.decode(npub);

    _ndk.accounts.loginPrivateKey(pubkey: hexPubkey, privkey: hexPrivkey);
    _initialized = true;
  }

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
    _ensureInitialized();

    final metadata = Metadata(
      pubKey: _ndk.accounts.getPublicKey()!,
      name: name,
      displayName: displayName,
      lud16: lud16,
      about: about,
      picture: picture,
      banner: banner,
      website: website,
      nip05: nip05,
    );

    return _ndk.metadata.broadcastMetadata(metadata);
  }

  Future<Metadata?> getMetadata(String pubkey) =>
      _ndk.metadata.loadMetadata(pubkey);

  Future<List<Metadata>> getMetadatas(
    List<String> pubkeys, {
    RelaySet? relaySet,
    void Function(Metadata)? onLoad,
  }) => _ndk.metadata.loadMetadatas(pubkeys, relaySet, onLoad: onLoad);

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
          'NostrService not initialized. Call initialize() first.');
    }
  }

  Future<void> dispose() => _ndk.destroy();
}
