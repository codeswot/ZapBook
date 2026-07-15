import 'package:injectable/injectable.dart';
import 'package:zapbook/features/profile/domain/entities/user_profile.dart';
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
  Future<void> importAndPersist(String nsec) => _repository.importAndPersist(nsec);
  
  Future<void> reloadSession() => _repository.reloadSession();
  
  Future<UserProfile?> fetchMetadata(String npub) => _repository.fetchMetadata(npub);
}
