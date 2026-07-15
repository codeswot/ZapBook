import 'package:zapbook/features/profile/domain/entities/user_profile.dart';

abstract class SwitchAccountRepository {
  Future<List<String>> listNpubs();
  Future<String?> readNpub();

  Future<void> setActive(String npub);
  Future<void> removeAccount(String npub);

  Future<bool> validateNsec(String nsec);
  Future<void> importAndPersist(String nsec);

  Future<void> reloadSession();

  Future<UserProfile?> fetchMetadata(String npub);
}
