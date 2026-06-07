import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart';

import 'package:zapbook/core/identity/nostr_signer_source.dart';
import 'package:zapbook/core/services/marmot_sync_service.dart';
import 'package:zapbook/core/services/nostr_service.dart';

@lazySingleton
class NostrSession {
  const NostrSession(this._ndk, this._signerSource, this._nostr, this._sync);

  final Ndk _ndk;
  final NostrSignerSource _signerSource;
  final NostrService _nostr;
  final MarmotSyncService _sync;

  bool get isLoggedIn => _ndk.accounts.isLoggedIn;

  String? get publicKey => _ndk.accounts.getPublicKey();

  Future<bool> login() async {
    final signer = await _signerSource.resolve();
    if (signer == null) return false;

    final pubkey = signer.getPublicKey();
    if (_ndk.accounts.hasAccount(pubkey)) {
      _ndk.accounts.switchAccount(pubkey: pubkey);
      _afterLogin();
      return true;
    }

    _ndk.accounts.loginExternalSigner(signer: signer);
    _afterLogin();
    return true;
  }

  void _afterLogin() {
    unawaited(_nostr.ensureRelayListPublished());
    unawaited(_sync.start());
  }

  void logout() {
    unawaited(_sync.stop());
    if (_ndk.accounts.isLoggedIn) {
      _ndk.accounts.logout();
    }
  }
}
