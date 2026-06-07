import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart';

import 'package:zapbook/core/identity/nostr_signer_source.dart';
import 'package:zapbook/core/services/nostr_service.dart';

@lazySingleton
class NostrSession {
  const NostrSession(this._ndk, this._signerSource, this._nostr);

  final Ndk _ndk;
  final NostrSignerSource _signerSource;
  final NostrService _nostr;

  bool get isLoggedIn => _ndk.accounts.isLoggedIn;

  String? get publicKey => _ndk.accounts.getPublicKey();

  Future<bool> login() async {
    final signer = await _signerSource.resolve();
    if (signer == null) return false;

    final pubkey = signer.getPublicKey();
    if (_ndk.accounts.hasAccount(pubkey)) {
      _ndk.accounts.switchAccount(pubkey: pubkey);
      _publishRelayList();
      return true;
    }

    _ndk.accounts.loginExternalSigner(signer: signer);
    _publishRelayList();
    return true;
  }

  void _publishRelayList() {
    unawaited(_nostr.ensureRelayListPublished());
  }

  void logout() {
    if (_ndk.accounts.isLoggedIn) {
      _ndk.accounts.logout();
    }
  }
}
