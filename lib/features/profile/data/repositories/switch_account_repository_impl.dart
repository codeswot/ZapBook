import 'package:injectable/injectable.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/identity/identity_repository.dart';
import 'package:zapbook/core/session/session_reloader.dart';
import 'package:zapbook/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:zapbook/features/profile/domain/entities/user_profile.dart';
import 'package:zapbook/features/profile/domain/repositories/switch_account_repository.dart';

@Injectable(as: SwitchAccountRepository)
class SwitchAccountRepositoryImpl implements SwitchAccountRepository {
  final IdentityLocalDataSource _identityLocal;
  final IdentityRepository _identityRepo;
  final ProfileRemoteDataSource _remote;
  final SessionReloader _sessionReloader;

  SwitchAccountRepositoryImpl(
    this._identityLocal,
    this._identityRepo,
    this._remote,
    this._sessionReloader,
  );

  @override
  Future<List<String>> listNpubs() => _identityLocal.listNpubs();

  @override
  Future<String?> readNpub() => _identityLocal.readNpub();

  @override
  Future<void> setActive(String npub) => _identityLocal.setActive(npub);

  @override
  Future<void> removeAccount(String npub) => _identityLocal.removeAccount(npub);

  @override
  Future<bool> validateNsec(String nsec) => _identityRepo.validateNsec(nsec);

  @override
  Future<void> importAndPersist(String nsec) async {
    final keypair = await _identityRepo.importFromNsec(nsec);
    final derivedNsec = keypair.nsec;
    if (derivedNsec == null || derivedNsec.isEmpty) {
      throw const FormatException('Could not derive secret key');
    }
    await _identityRepo.persist(npub: keypair.npub, nsec: derivedNsec);
  }

  @override
  Future<bool> isExternalSignerAvailable() =>
      _identityRepo.isExternalSignerAvailable();

  @override
  Future<void> connectExternalSigner() async {
    final connection = await _identityRepo.connectExternalSigner();
    await _identityRepo.persistExternal(
      npub: connection.npub,
      package: connection.package,
    );
  }

  @override
  Future<void> reloadSession() => _sessionReloader.reload();

  @override
  Future<UserProfile?> fetchMetadata(String npub) async {
    final meta = await _remote.fetchMetadata(npub: npub);
    if (meta == null) return null;
    return UserProfile(
      npub: npub,
      displayName: meta.displayName ?? meta.name ?? npub,
      picture: meta.picture ?? '',
      lightningAddress: meta.lud16 ?? '',
      satsEarned: 0,
      dayStreak: 0,
      booksRead: 0,
      milestones: 0,
    );
  }
}
