import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart';

import 'package:zapbook/core/data/cache/drift_cache_manager.dart';
import 'package:zapbook/core/data/cache/nostr_cache_store.dart';

@module
abstract class NostrModule {
  @preResolve
  @lazySingleton
  Future<Ndk> ndk() async {
    final store = await NostrCacheStore.open();
    return Ndk(
      NdkConfig(
        engine: NdkEngine.JIT,
        cache: DriftCacheManager(store),
        eventVerifier: Bip340EventVerifier(),
      ),
    );
  }
}
