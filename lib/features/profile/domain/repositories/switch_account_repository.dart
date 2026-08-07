import 'package:zapbook/features/profile/domain/entities/user_profile.dart';
import 'package:zapbook/core/identity/bunker_signer_source.dart';

abstract class SwitchAccountRepository {
  Future<List<String>> listNpubs();
  Future<String?> readNpub();

  Future<void> setActive(String npub);
  Future<void> removeAccount(String npub);

  Future<bool> validateNsec(String nsec);
  Future<String> importAndPersist(String nsec);

  Future<bool> isExternalSignerAvailable();
  Future<String> connectExternalSigner();
  Future<String> connectBunker(String bunkerUrl);
  NostrConnectSession initiateNostrConnect({required String appName});
  Future<void> saveBunkerConnection(BunkerConnectResult result);

  Future<void> reloadSession();

  Future<UserProfile?> fetchMetadata(String npub);
}
