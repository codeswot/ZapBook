import 'package:injectable/injectable.dart';
import 'package:zapbook/core/data/database/dao/zap_sats_earnings_dao.dart';

import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/identity/nostr_session.dart';
import 'package:zapbook/core/extensions/string_extension.dart';
import 'package:zapbook/core/utils/profile_meta_generator.dart';

import 'package:zapbook/core/data/infrastructure/reading_stats_service.dart';
import 'package:zapbook/core/session/session_reloader.dart';
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
    this._session,
    this._stats,
    this._reloader,
    this._earningsDao,
  );

  final IdentityLocalDataSource _identityLocal;
  final ProfileRemoteDataSource _remote;
  final OnboardingLocalDataSource _onboardingLocal;
  final NostrSession _session;
  final ReadingStatsService _stats;
  final SessionReloader _reloader;
  final ZapSatsEarningsDao _earningsDao;

  @override
  Future<UserProfile> load() async {
    final npub = await _identityLocal.readNpub() ?? '';

    final statsRecord = await _stats.getStats(null);

    final fallbackAvatar = ProfileMetaGenerator.generate(seed: npub).avatar;
    final fallbackName = npub.toNpubShort();
    final metadata = await _remote.fetchMetadata(npub: npub);

    final fetchedName = metadata?.displayName ?? metadata?.name;
    final fetchedPicture = metadata?.picture;

    return UserProfile(
      npub: npub,
      displayName: (fetchedName != null && fetchedName.isNotEmpty)
          ? fetchedName
          : fallbackName,
      picture: (fetchedPicture != null && fetchedPicture.isNotEmpty)
          ? fetchedPicture
          : fallbackAvatar,
      lightningAddress: metadata?.lud16 ?? '',
      satsEarned: await _earningsDao.getTotalSats(),
      dayStreak: statsRecord?.effectiveStreak ?? 0,
      booksRead: statsRecord?.booksRead ?? 0,
      milestones: await _stats.getMilestones(),
    );
  }

  @override
  Future<void> update({
    String? displayName,
    String? lud16,
    String? picture,
  }) async {
    if (!_session.isLoggedIn) return;
    await _remote.publish(
      displayName: displayName,
      lud16: lud16,
      picture: picture,
    );
  }

  @override
  Future<void> signOut() async {
    await _identityLocal.clear();
    await _onboardingLocal.clear();

    await _reloader.reload();
  }
}
