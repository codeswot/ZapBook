import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart';

import 'package:zapbook/core/identity/nip55_event_signer.dart';
import 'package:zapbook/core/identity/nip55_signer.dart';
import 'package:zapbook/core/identity/signer_meta.dart';

@lazySingleton
class Nip55SignerSource {
  const Nip55SignerSource(this._channel);

  final Nip55Signer _channel;

  Future<EventSigner?> resolve(String npub, SignerMeta meta) async {
    final package = meta.package;
    if (package == null || package.isEmpty) return null;
    final hex = Nip19.decode(npub);
    if (hex.isEmpty) return null;
    return Nip55EventSigner(_channel, hex, package);
  }
}
