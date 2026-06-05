import 'package:injectable/injectable.dart';
import 'package:marmot_dart/marmot_dart.dart';

import 'package:zapbook/core/identity/identity_repository.dart';

@injectable
final class GenerateIdentity {
  const GenerateIdentity(this._identity);

  final IdentityRepository _identity;

  Future<NostrKeypair> call() => _identity.generate();
}
