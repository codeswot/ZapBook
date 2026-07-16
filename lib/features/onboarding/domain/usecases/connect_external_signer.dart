import 'package:injectable/injectable.dart';

import 'package:zapbook/core/identity/identity_repository.dart';

@injectable
class ConnectExternalSigner {
  const ConnectExternalSigner(this._identity);

  final IdentityRepository _identity;

  Future<bool> isAvailable() => _identity.isExternalSignerAvailable();

  Future<ExternalSignerConnection> call() => _identity.connectExternalSigner();
}
