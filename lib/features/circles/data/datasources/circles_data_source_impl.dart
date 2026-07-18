import 'package:injectable/injectable.dart';
import 'package:zapbook/core/data/database/dao/circle_progress_dao.dart';
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/models/circle_member_progress.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:logging/logging.dart' as logging;
import 'package:zapbook/core/data/infrastructure/circle_store_service.dart';
import 'package:zapbook/core/data/infrastructure/contact_service.dart';
import 'package:zapbook/core/data/infrastructure/zap_nudge_service.dart';
import 'package:zapbook/core/data/infrastructure/zap_service.dart';
import 'package:zapbook/core/data/infrastructure/circle_share_service.dart';
import 'package:zapbook/core/data/infrastructure/group_envelope_service.dart';
import 'package:zapbook/core/data/infrastructure/key_package_service.dart';
import 'package:zapbook/core/data/infrastructure/group_store_service.dart';
import 'package:zapbook/features/circles/domain/entities/share_skip.dart';
import 'package:zapbook/core/data/database/dao/zap_sats_earnings_dao.dart';
import 'package:ndk/ndk.dart';
import 'package:zapbook/features/circles/data/datasources/circles_data_source.dart';

@LazySingleton(as: CirclesDataSource)
class CirclesDataSourceImpl implements CirclesDataSource {
  CirclesDataSourceImpl(
    this._circleStore,
    this._contacts,
    this._progressDao,
    this._identityLocal,
    this._zapService,
    this._nudgeService,
    this._keyPackageService,
    this._envelopeService,
    this._shareService,
    this._groupStore,
    this._marmot,
  );

  final CircleStoreService _circleStore;
  final ContactService _contacts;
  final CircleProgressDao _progressDao;
  final IdentityLocalDataSource _identityLocal;
  final ZapService _zapService;
  final ZapNudgeService _nudgeService;
  final KeyPackageService _keyPackageService;
  final GroupEnvelopeService _envelopeService;
  final CircleShareService _shareService;
  final GroupStoreService _groupStore;
  final Marmot _marmot;
  final _log = logging.Logger('CirclesDataSourceImpl');

  @override
  Stream<List<CircleBook>> watchSharedCircles() {
    return _circleStore.watchCircleBooks;
  }

  @override
  Future<List<Contact>> getCircleMembers(String circleId) {
    return _circleStore.getCircleMembers(circleId);
  }

  @override
  Future<CircleBook?> getCircleBook(String circleId) async {
    return _circleStore.currentCircles
        .where((c) => c.id == circleId)
        .firstOrNull;
  }

  @override
  Future<void> removeCircleMember(String circleId, String npub) {
    return _circleStore.removeCircleMember(circleId, npub);
  }

  @override
  Future<void> toggleContact(String npub, bool isFollow) async {
    if (isFollow) {
      await _contacts.remove(npub);
    } else {
      await _contacts.add(npub);
    }
  }

  @override
  Future<void> leaveCircleBook(CircleBook circleBook) {
    return _circleStore.leaveCircleBook(circleBook);
  }

  @override
  Future<void> deleteCircleBook(CircleBook circleBook) {
    return _circleStore.deleteCircleBook(circleBook);
  }

  @override
  Stream<List<CircleMemberProgress>> watchProgressByBook({
    required String groupId,
    required String bookId,
  }) {
    return _progressDao.watchProgressByBook(groupId: groupId, bookId: bookId);
  }

  @override
  Future<String?> getMyNpub() {
    return _identityLocal.readNpub();
  }

  @override
  Future<void> sendZap({
    required Contact reader,
    required ZapGesture gesture,
    required String circleId,
  }) async {
    final lud16 = reader.lud16;
    if (lud16 == null || lud16.isEmpty) {
      await _nudgeService.nudge(groupId: circleId, toNpub: reader.npub);
      throw Exception('\${reader.label} has no lightning address');
    }

    final result = await _zapService.send(
      recipientLud16: lud16,
      recipientPubkey: reader.npub,
      targetActivitytId: circleId,
      zapType: ZapType.circle,
      gesture: gesture,
    );

    await _zapService.payZap(result);
  }

  @override
  Future<List<ShareSkip>> shareCircleBook({
    required String circleBookId,
    required List<String> npubs,
    required String myNpub,
  }) async {
    final book = _circleStore.currentCircles
        .where((b) => b.id == circleBookId)
        .firstOrNull;
    if (book == null) return [];

    final groupId = book.id;
    final skips = <ShareSkip>[];

    final fetchFutures = npubs.map((npub) async {
      try {
        final kp = await _keyPackageService.fetchKeyPackage(
          npub,
          forceRefresh: true,
        );
        return MapEntry(npub, kp);
      } catch (e, st) {
        _log.warning('Failed to fetch key package for $npub', e, st);
        return MapEntry(npub, null);
      }
    });

    final keyPackages = await Future.wait(fetchFutures);
    final publishFutures = <Future<void>>[];

    for (final entry in keyPackages) {
      final npub = entry.key;
      final keyPackageJson = entry.value;

      if (keyPackageJson == null) {
        _log.warning('No key package found for $npub');
        skips.add(ShareSkip(npub: npub, reason: ShareSkipReason.noKeyPackage));
        continue;
      }

      try {
        MemberChangeResult? result;
        int retries = 0;

        while (result == null && retries < 20) {
          result = await _circleStore.addCircleMember(groupId, keyPackageJson);

          if (result == null) {
            _log.info(
              'addCircleMember returned null (likely pending commit), waiting... ($retries/20)',
            );
            await Future.delayed(const Duration(milliseconds: 1000));
            retries++;
          }
        }

        if (result == null) {
          _log.warning('Failed to add member $npub after retries');
          skips.add(
            ShareSkip(npub: npub, reason: ShareSkipReason.unknownError),
          );
          continue;
        }

        final hex = await MarmotIdentity.pubkeyHexFromNpub(npub);

        for (final rumorJson in result.welcomeRumors) {
          publishFutures.add(
            _envelopeService.giftWrapAndPublish(rumorJson, hex).catchError((
              e,
              st,
            ) {
              _log.severe('Failed to publish welcome rumor for $npub', e, st);
            }),
          );
        }
      } catch (e, stack) {
        _log.severe('Failed to add member', e, stack);
        skips.add(ShareSkip(npub: npub, reason: ShareSkipReason.unknownError));
      }
    }

    if (publishFutures.isNotEmpty) {
      await Future.wait(publishFutures);
    }

    if (skips.length < npubs.length) {
      await _shareService.uploadBookContent(myNpub, groupId, book.circleDirId);
      await _groupStore.refreshGroup(groupId);
    }

    return skips;
  }

  @override
  Future<List<Contact>> getFriends() async {
    return _contacts.friends.first;
  }

  @override
  Future<Set<String>> getExistingMemberNpubs(String circleBookId) async {
    final book = _circleStore.currentCircles
        .where((b) => b.id == circleBookId)
        .firstOrNull;
    final existingMembers = <String>{};

    if (book != null && book.id.isNotEmpty) {
      try {
        final members = await _marmot.getMembers(book.id);
        for (final member in members) {
          try {
            final npub = Nip19.encodePubKey(member.pubkeyHex);
            existingMembers.add(npub);
          } catch (_) {}
        }
      } catch (e, stack) {
        _log.warning('Failed to load group members', e, stack);
      }
    }

    return existingMembers;
  }
}
