import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ndk/ndk.dart' show Nip19;

class ActiveAccount {
  ActiveAccount._();

  static const activeNpubKey = 'active_npub';
  static const _pendingScope = '_pending';

  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static String? _hex;

  static String get scope => _hex ?? _pendingScope;

  static bool get hasActive => _hex != null;

  static String key(String base) => '$scope:$base';

  static Future<void> resolve() async {
    final npub = await _storage.read(key: activeNpubKey);
    setNpub(npub);
  }

  static void setNpub(String? npub) {
    _hex = (npub == null || npub.isEmpty) ? null : _hexOf(npub);
  }

  static String? _hexOf(String npub) {
    try {
      final hex = Nip19.decode(npub);
      return hex.isEmpty ? null : hex;
    } on Object {
      return null;
    }
  }
}
