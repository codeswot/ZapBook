import 'package:injectable/injectable.dart';

import 'package:zapbook/core/data/database/dao/circle_progress_dao.dart';
import 'package:zapbook/core/data/infrastructure/contact_service.dart';
import 'package:zapbook/core/data/infrastructure/reading_stats_service.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/data/infrastructure/zap_service.dart';
import 'package:zapbook/core/data/database/dao/zap_sats_earnings_dao.dart'
    show ZapType;
import 'package:zapbook/core/domain/entities/zap_status.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/extensions/string_extension.dart';
import 'package:zapbook/core/utils/profile_meta_generator.dart';
import 'package:zapbook/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:zapbook/features/profile/domain/entities/user_profile.dart';
import 'package:zapbook/features/profile/domain/repositories/user_profile_repository.dart';

@LazySingleton(as: UserProfileRepository)
class UserProfileRepositoryImpl implements UserProfileRepository {
  UserProfileRepositoryImpl(
    this._remote,
    this._stats,
    this._progressDao,
    this._zapService,
    this._contacts,
    this._identity,
  );

  final ProfileRemoteDataSource _remote;
  final ReadingStatsService _stats;
  final CircleProgressDao _progressDao;
  final ZapService _zapService;
  final ContactService _contacts;
  final IdentityLocalDataSource _identity;

  @override
  Future<UserProfile> load(String npub) async {
    final fallbackAvatar = ProfileMetaGenerator.generate(seed: npub).avatar;
    final fallbackName = npub.toNpubShort();
    final metadata = await _remote.fetchMetadata(
      npub: npub,
      forceRefresh: true,
    );

    final fetchedName = metadata?.displayName ?? metadata?.name;
    final fetchedPicture = metadata?.picture;

    final statsRecord = await _stats.getStats(npub);
    final localBooksRead = await _progressDao.countCompletedBooks(npub);
    final milestones = await _progressDao.sumMilestonesReached(npub);
    final myNpub = await _identity.readNpub();

    return UserProfile(
      npub: npub,
      displayName: (fetchedName != null && fetchedName.isNotEmpty)
          ? fetchedName
          : fallbackName,
      picture: (fetchedPicture != null && fetchedPicture.isNotEmpty)
          ? fetchedPicture
          : fallbackAvatar,
      lightningAddress: metadata?.lud16 ?? '',
      satsEarned: 0,
      dayStreak: statsRecord?.effectiveStreak ?? 0,
      booksRead: (statsRecord?.booksRead ?? 0) > localBooksRead
          ? statsRecord!.booksRead
          : localBooksRead,
      milestones: milestones,
      isFollow: _contacts.contactFor(npub).isFollow,
      isSelf: npub == myNpub,
    );
  }

  @override
  Future<void> toggleFollow(String npub, bool isFollow) async {
    if (isFollow) {
      await _contacts.remove(npub);
    } else {
      await _contacts.add(npub);
    }
  }

  @override
  Future<void> zap({
    required UserProfile profile,
    required ZapGesture gesture,
    int? customSats,
    String? comment,
  }) async {
    if (!profile.hasLightning) {
      throw ZapException('${profile.displayName} has no lightning address');
    }

    final result = await _zapService.send(
      recipientLud16: profile.lightningAddress,
      recipientPubkey: profile.npub,
      targetActivitytId: profile.npub,
      gesture: gesture,
      customSats: customSats,
      comment: comment,
      zapType: ZapType.profile,
    );

    await _zapService.payZap(result);
  }
}
