import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart';

import 'package:zapbook/core/data/cache/local_cache_manager.dart';
import 'package:zapbook/core/data/cache/nostr_cache_store.dart';

final class NostrCacheWarmup {
  const NostrCacheWarmup._();

  static Future<NostrCacheStore>? _warmStore;

  static Future<NostrCacheStore> start() =>
      _warmStore ??= NostrCacheStore.open();

  static void reset() => _warmStore = null;
}

@module
abstract class NostrModule {
  @preResolve
  @lazySingleton
  Future<NostrCacheStore> cacheStore() => NostrCacheWarmup.start();

  @preResolve
  @lazySingleton
  Future<Ndk> ndk(NostrCacheStore store) async {
    return Ndk(
      NdkConfig(
        engine: NdkEngine.JIT,
        cache: LocalCacheManager(store),
        eventVerifier: Bip340EventVerifier(),
        bootstrapRelays: const [
          'wss://relay.damus.io',
          'wss://nos.lol',
          'wss://relay.nostr.band',
          'wss://relay.primal.net',
          'wss://relay.snort.social',
          'wss://nostr.wine',
        ],
      ),
    );
  }
}
