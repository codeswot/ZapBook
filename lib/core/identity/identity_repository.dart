import 'package:marmot_dart/marmot_dart.dart';

abstract interface class IdentityRepository {
  Future<NostrKeypair> generate();

  Future<NostrKeypair> importFromNsec(String nsec);

  Future<bool> validateNsec(String nsec);

  Future<void> persist({required String npub, required String nsec});

  Future<String?> currentNpub();

  Future<String?> currentNsec();

  Future<bool> hasIdentity();
}
