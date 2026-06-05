import 'package:injectable/injectable.dart';
import 'package:marmot_dart/marmot_dart.dart';

import 'package:zapbook/core/identity/identity_repository.dart';

@injectable
final class ImportIdentity {
  const ImportIdentity(this._identity);

  final IdentityRepository _identity;

  Future<NostrKeypair> call(String nsec) async {
    final trimmed = nsec.trim();
    final isValid = await _identity.validateNsec(trimmed);
    if (!isValid) {
      throw const FormatException('Invalid secret key');
    }
    return _identity.importFromNsec(trimmed);
  }
}
