import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/data/database/dao/circle_progress_dao.dart';
import 'package:zapbook/core/data/database/dao/reading_stats_dao.dart';
import 'package:zapbook/core/data/database/dao/zap_sats_earnings_dao.dart'
    show ZapType;
import 'package:zapbook/core/data/infrastructure/contact_service.dart';
import 'package:zapbook/core/data/infrastructure/reading_stats_service.dart';
import 'package:zapbook/core/data/infrastructure/zap_service.dart';
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/domain/entities/zap_status.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:zapbook/features/profile/data/repositories/user_profile_repository_impl.dart';
import 'package:zapbook/features/profile/domain/entities/user_profile.dart';

class MockProfileRemoteDataSource extends Mock
    implements ProfileRemoteDataSource {}

class MockReadingStatsService extends Mock implements ReadingStatsService {}

class MockCircleProgressDao extends Mock implements CircleProgressDao {}

class MockZapService extends Mock implements ZapService {}

class MockContactService extends Mock implements ContactService {}

class MockIdentityLocalDataSource extends Mock
    implements IdentityLocalDataSource {}

void main() {
  late MockProfileRemoteDataSource remote;
  late MockReadingStatsService stats;
  late MockCircleProgressDao progressDao;
  late MockZapService zapService;
  late MockContactService contacts;
  late MockIdentityLocalDataSource identity;
  late UserProfileRepositoryImpl repository;

  const npub = 'npub1abc';
  final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);

  setUpAll(() {
    registerFallbackValue(ZapGesture.fire);
  });

  setUp(() {
    remote = MockProfileRemoteDataSource();
    stats = MockReadingStatsService();
    progressDao = MockCircleProgressDao();
    zapService = MockZapService();
    contacts = MockContactService();
    identity = MockIdentityLocalDataSource();
    when(() => contacts.contactFor(npub)).thenReturn(const Contact(npub: npub));
    when(() => identity.readNpub()).thenAnswer((_) async => 'npub1me');
    repository = UserProfileRepositoryImpl(
      remote,
      stats,
      progressDao,
      zapService,
      contacts,
      identity,
    );
  });

  group('load', () {
    test('uses fetched metadata and remote booksRead when higher', () async {
      when(
        () => remote.fetchMetadata(npub: npub, forceRefresh: true),
      ).thenAnswer(
        (_) async => (
          name: 'alice',
          displayName: 'Alice',
          picture: 'https://example.com/alice.png',
          lud16: 'alice@getalby.com',
        ),
      );
      when(() => stats.getStats(npub)).thenAnswer(
        (_) async => ReadingStatsRecord(
          pubKey: npub,
          streak: 7,
          lastActivityDate: today,
          booksRead: 5,
          updatedAt: 0,
        ),
      );
      when(
        () => progressDao.countCompletedBooks(npub),
      ).thenAnswer((_) async => 2);
      when(
        () => progressDao.sumMilestonesReached(npub),
      ).thenAnswer((_) async => 3);

      final profile = await repository.load(npub);

      expect(profile.npub, npub);
      expect(profile.displayName, 'Alice');
      expect(profile.picture, 'https://example.com/alice.png');
      expect(profile.lightningAddress, 'alice@getalby.com');
      expect(profile.dayStreak, 7);
      expect(profile.booksRead, 5);
      expect(profile.milestones, 3);
      expect(profile.satsEarned, 0);
    });

    test(
      'falls back to local booksRead when it is higher than remote',
      () async {
        when(
          () => remote.fetchMetadata(npub: npub, forceRefresh: true),
        ).thenAnswer((_) async => null);
        when(() => stats.getStats(npub)).thenAnswer(
          (_) async => ReadingStatsRecord(
            pubKey: npub,
            streak: 1,
            lastActivityDate: today,
            booksRead: 1,
            updatedAt: 0,
          ),
        );
        when(
          () => progressDao.countCompletedBooks(npub),
        ).thenAnswer((_) async => 4);
        when(
          () => progressDao.sumMilestonesReached(npub),
        ).thenAnswer((_) async => 0);

        final profile = await repository.load(npub);

        expect(profile.booksRead, 4);
      },
    );

    test(
      'falls back to generated avatar and short npub when metadata missing',
      () async {
        when(
          () => remote.fetchMetadata(npub: npub, forceRefresh: true),
        ).thenAnswer((_) async => null);
        when(() => stats.getStats(npub)).thenAnswer((_) async => null);
        when(
          () => progressDao.countCompletedBooks(npub),
        ).thenAnswer((_) async => 0);
        when(
          () => progressDao.sumMilestonesReached(npub),
        ).thenAnswer((_) async => 0);

        final profile = await repository.load(npub);

        expect(profile.displayName, npub);
        expect(profile.picture, startsWith('https://api.dicebear.com'));
        expect(profile.lightningAddress, '');
        expect(profile.dayStreak, 0);
        expect(profile.booksRead, 0);
      },
    );
  });

  group('zap', () {
    const profileWithLightning = UserProfile(
      npub: npub,
      displayName: 'Alice',
      picture: '',
      lightningAddress: 'alice@getalby.com',
      satsEarned: 0,
      dayStreak: 0,
      booksRead: 0,
      milestones: 0,
    );

    const profileWithoutLightning = UserProfile(
      npub: npub,
      displayName: 'Alice',
      picture: '',
      lightningAddress: '',
      satsEarned: 0,
      dayStreak: 0,
      booksRead: 0,
      milestones: 0,
    );

    test('throws ZapException when profile has no lightning address', () async {
      expect(
        () => repository.zap(
          profile: profileWithoutLightning,
          gesture: ZapGesture.fire,
        ),
        throwsA(isA<ZapException>()),
      );
      verifyNever(
        () => zapService.send(
          recipientLud16: any(named: 'recipientLud16'),
          recipientPubkey: any(named: 'recipientPubkey'),
          targetActivitytId: any(named: 'targetActivitytId'),
          gesture: any(named: 'gesture'),
        ),
      );
    });

    test('sends and pays zap when profile has a lightning address', () async {
      final result = ZapResult(
        invoice: 'lnbc1...',
        zapRequestId: 'req1',
        amountSats: 1000,
        gesture: ZapGesture.fire,
        recipientPubkey: npub,
        targetActivitytId: npub,
      );

      when(
        () => zapService.send(
          recipientLud16: 'alice@getalby.com',
          recipientPubkey: npub,
          targetActivitytId: npub,
          gesture: ZapGesture.fire,
          customSats: null,
          comment: null,
          zapType: ZapType.profile,
        ),
      ).thenAnswer((_) async => result);
      when(
        () => zapService.payZap(result),
      ).thenAnswer((_) async => ZapStatus.paidNwc);

      await repository.zap(
        profile: profileWithLightning,
        gesture: ZapGesture.fire,
      );

      verify(() => zapService.payZap(result)).called(1);
    });
  });
}
