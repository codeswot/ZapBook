import 'package:injectable/injectable.dart';
import 'package:zapbook/features/profile/domain/entities/user_profile.dart';
import 'package:zapbook/core/identity/bunker_signer_source.dart';
import 'package:zapbook/features/profile/domain/repositories/switch_account_repository.dart';

@injectable
class SwitchAccountUseCases {
  final SwitchAccountRepository _repository;

  SwitchAccountUseCases(this._repository);

  Future<List<String>> listNpubs() => _repository.listNpubs();
  Future<String?> readNpub() => _repository.readNpub();

  Future<void> setActive(String npub) => _repository.setActive(npub);
  Future<void> removeAccount(String npub) => _repository.removeAccount(npub);

  Future<bool> validateNsec(String nsec) => _repository.validateNsec(nsec);
  Future<String> importAndPersist(String nsec) =>
      _repository.importAndPersist(nsec);

  Future<bool> isExternalSignerAvailable() =>
      _repository.isExternalSignerAvailable();
  Future<String> connectExternalSigner() => _repository.connectExternalSigner();
  Future<String> connectBunker(String bunkerUrl) =>
      _repository.connectBunker(bunkerUrl);
  NostrConnectSession initiateNostrConnect({required String appName}) =>
      _repository.initiateNostrConnect(appName: appName);
  Future<void> saveBunkerConnection(BunkerConnectResult result) =>
      _repository.saveBunkerConnection(result);

  Future<void> reloadSession() => _repository.reloadSession();

  Future<UserProfile?> fetchMetadata(String npub) =>
      _repository.fetchMetadata(npub);
}
