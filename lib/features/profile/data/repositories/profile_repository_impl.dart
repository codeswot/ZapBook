import 'package:injectable/injectable.dart';

import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/nostr_service.dart';
import 'package:zapbook/core/services/nwc_service.dart';
import 'package:zapbook/core/services/profile_meta_generator.dart';
import 'package:zapbook/core/data/datasources/onboarding_local_datasource.dart';
import 'package:zapbook/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:zapbook/features/profile/domain/entities/user_profile.dart';
import 'package:zapbook/features/profile/domain/repositories/profile_repository.dart';

@LazySingleton(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(
    this._identityLocal,
    this._remote,
    this._onboardingLocal,
    this._nostr,
    this._nwc,
  );

  final IdentityLocalDataSource _identityLocal;
  final ProfileRemoteDataSource _remote;
  final OnboardingLocalDataSource _onboardingLocal;
  final NostrService _nostr;
  final NwcService _nwc;

  @override
  Future<UserProfile> load() async {
    final npub = await _identityLocal.readNpub() ?? '';
    final nsec = await _identityLocal.readNsec() ?? '';

    final fallback = ProfileMetaGenerator.generate(seed: npub);
    final metadata = await _remote.fetchMetadata(npub: npub, nsec: nsec);

    final fetchedName = metadata?.displayName ?? metadata?.name;
    final fetchedPicture = metadata?.picture;

    return UserProfile(
      npub: npub,
      displayName: (fetchedName != null && fetchedName.isNotEmpty)
          ? fetchedName
          : fallback.displayName,
      picture: (fetchedPicture != null && fetchedPicture.isNotEmpty)
          ? fetchedPicture
          : fallback.avatar,
      lightningAddress: metadata?.lud16 ?? '',
      satsEarned: 0,
      dayStreak: 0,
      booksRead: 0,
      milestones: 0,
      joinedYear: DateTime.now().year,
    );
  }

  @override
  Future<void> signOut() async {
    _nostr.clearSession();
    await _nwc.disconnect();
    await _identityLocal.clear();
    await _onboardingLocal.clear();
  }
}
