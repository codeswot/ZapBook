import 'package:injectable/injectable.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/identity/identity_repository.dart';
import 'package:zapbook/core/session/session_reloader.dart';
import 'package:zapbook/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:zapbook/features/profile/domain/entities/user_profile.dart';

@injectable
class SwitchAccountUseCases {
  final IdentityLocalDataSource _identityLocal;
  final IdentityRepository _identityRepo;
  final ProfileRemoteDataSource _remote;
  final SessionReloader _sessionReloader;

  SwitchAccountUseCases(
    this._identityLocal,
    this._identityRepo,
    this._remote,
    this._sessionReloader,
  );

  Future<List<String>> listNpubs() => _identityLocal.listNpubs();
  Future<String?> readNpub() => _identityLocal.readNpub();
  
  Future<void> setActive(String npub) => _identityLocal.setActive(npub);
  Future<void> removeAccount(String npub) => _identityLocal.removeAccount(npub);
  
  Future<bool> validateNsec(String nsec) => _identityRepo.validateNsec(nsec);
  Future<void> importAndPersist(String nsec) async {
    final keypair = await _identityRepo.importFromNsec(nsec);
    await _identityRepo.persist(npub: keypair.npub, nsec: keypair.nsec!);
  }
  
  Future<void> reloadSession() => _sessionReloader.reload();
  
  Future<UserProfile?> fetchMetadata(String npub) async {
    final meta = await _remote.fetchMetadata(npub: npub);
    if (meta == null) return null;
    return UserProfile(
      npub: npub,
      displayName: meta.displayName ?? meta.name,
      picture: meta.picture,
      lightningAddress: meta.lud16 ?? '',
      satsEarned: 0,
      dayStreak: 0,
      booksRead: 0,
      milestones: [],
    );
  }
}
