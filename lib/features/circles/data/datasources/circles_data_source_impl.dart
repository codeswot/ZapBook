import 'package:injectable/injectable.dart';
import 'package:zapbook/core/data/database/dao/circle_progress_dao.dart';
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/core/models/book_manifest_payload.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/core/domain/entities/pending_circle_upload.dart';
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
import 'package:zapbook/core/data/database/dao/pending_circle_upload_dao.dart';
import 'package:zapbook/core/data/database/dao/circle_reseed_ack_dao.dart';
import 'package:zapbook/core/data/database/dao/cheers_dao.dart';
import 'package:zapbook/core/domain/entities/cheers_activity_message.dart';
import 'package:zapbook/core/domain/entities/cheers_activity_type.dart';
import 'package:zapbook/core/domain/book_group_naming.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';
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
    this._pendingUploadDao,
    this._reseedAckDao,
    this._cheersDao,
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
  final PendingCircleUploadDao _pendingUploadDao;
  final CircleReseedAckDao _reseedAckDao;
  final CheersDao _cheersDao;
  final _log = logging.Logger('CirclesDataSourceImpl');

  final _activeUploadsController = BehaviorSubject<Set<String>>.seeded(
    const {},
  );

  @override
  Stream<Set<String>> watchActiveUploads() => _activeUploadsController.stream;

  @override
  Set<String> get activeUploads => _activeUploadsController.value;

  static const _uploadMaxAttempts = 3;

  @override
  Future<void> uploadCircleBook(String myNpub, String circleBookId) async {
    final book = _circleStore.currentCircles
        .where((b) => b.id == circleBookId)
        .firstOrNull;
    if (book == null) return;
    await _uploadWithRetry(myNpub, book.id, book.circleDirId);
  }

  Future<void> _uploadWithRetry(
    String npub,
    String groupId,
    String circleDirId,
  ) async {
    var uploaded = <String, BookManifestFile>{};

    final currentUploads = Set<String>.from(_activeUploadsController.value)
      ..add(circleDirId);
    _activeUploadsController.add(currentUploads);

    try {
      for (var attempt = 1; attempt <= _uploadMaxAttempts; attempt++) {
        UploadOutcome? outcome;
        try {
          outcome = await _shareService.uploadBookContent(
            npub,
            groupId,
            circleDirId,
            alreadyUploaded: uploaded,
          );
        } catch (e, st) {
          outcome = (manifest: null, uploaded: uploaded, error: e, stack: st);
        }

        uploaded.addAll(outcome.uploaded);
        if (outcome.manifest != null) {
          _log.fine('Successfully uploaded book content for $circleDirId');
        }

        if (outcome.error == null) {
          await _pendingUploadDao.clear(circleDirId);
          return;
        }

        final isLastAttempt = attempt == _uploadMaxAttempts;
        _log.warning(
          'Upload attempt $attempt/$_uploadMaxAttempts failed for $circleDirId',
          outcome.error,
          outcome.stack,
        );
        if (isLastAttempt) {
          await _pendingUploadDao.markFailed(
            circleDirId: circleDirId,
            groupId: groupId,
            ownerNpub: npub,
            attempts: attempt,
            reason: outcome.error.toString(),
          );

          try {
            final group = await _marmot.getGroup(groupId);
            final title = group != null
                ? (BookGroupNaming.matches(group.name)
                      ? BookGroupNaming.titleOf(group.name)
                      : group.name)
                : null;

            final activity = CheersActivityMessage(
              id: const Uuid().v4(),
              actorNpub: npub,
              circleBookId: circleDirId,
              groupId: groupId,
              activityDescription:
                  'Book upload failed after $_uploadMaxAttempts attempts. Please retry.',
              timestamp: DateTime.now(),
              type: CheersActivityType.adminAction,
              isUnread: true,
              bookTitle: title,
            );
            await _cheersDao.saveActivity(npub, activity);
          } catch (e, st) {
            _log.warning('Failed to log admin action for failed upload', e, st);
          }

          throw Exception('Upload failed: ${outcome.error}');
        }
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    } finally {
      final updatedUploads = Set<String>.from(_activeUploadsController.value)
        ..remove(circleDirId);
      _activeUploadsController.add(updatedUploads);
    }
  }

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
    return _circleStore.removeCircleMembers(circleId, [npub]);
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

    final validEntries = <MapEntry<String, String>>[];

    for (final entry in keyPackages) {
      if (entry.value == null) {
        _log.warning('No key package found for ${entry.key}');
        skips.add(
          ShareSkip(npub: entry.key, reason: ShareSkipReason.noKeyPackage),
        );
      } else {
        validEntries.add(MapEntry(entry.key, entry.value!));
      }
    }

    if (validEntries.isNotEmpty) {
      final validJsons = validEntries.map((e) => e.value).toList();
      try {
        final result = await _circleStore.addCircleMembers(groupId, validJsons);

        if (result == null) {
          _log.warning('Failed to add members in bulk');
          for (final entry in validEntries) {
            skips.add(
              ShareSkip(npub: entry.key, reason: ShareSkipReason.unknownError),
            );
          }
        } else {
          for (var i = 0; i < result.welcomeRumors.length; i++) {
            final npub = validEntries[i].key;
            final hex = await MarmotIdentity.pubkeyHexFromNpub(npub);
            final rumorJson = result.welcomeRumors[i];

            publishFutures.add(
              _envelopeService.giftWrapAndPublish(rumorJson, hex).catchError((
                e,
                st,
              ) {
                _log.severe('Failed to publish welcome rumor for $npub', e, st);
              }),
            );
          }
        }
      } catch (e, stack) {
        _log.severe('Failed to add members', e, stack);
        for (final entry in validEntries) {
          skips.add(
            ShareSkip(npub: entry.key, reason: ShareSkipReason.unknownError),
          );
        }
      }
    }

    if (publishFutures.isNotEmpty) {
      await Future.wait(publishFutures);
    }

    if (skips.length < npubs.length) {
      final manifest = await _shareService.getLatestManifest(
        groupId,
        book.circleDirId,
      );
      if (manifest != null) {
        try {
          await _shareService.broadcastManifest(myNpub, groupId, manifest);
        } catch (e, st) {
          _log.warning('Failed to re-broadcast manifest to new members', e, st);
        }
      }

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

  @override
  Stream<List<PendingCircleUpload>> watchPendingUploads(String ownerNpub) {
    return _pendingUploadDao.watchAll(ownerNpub);
  }

  @override
  Future<void> retryPendingUpload(PendingCircleUpload upload) {
    return _uploadWithRetry(
      upload.ownerNpub,
      upload.groupId,
      upload.circleDirId,
    );
  }

  @override
  Future<List<String>> getReseedRequesters({
    required String groupId,
    required String circleDirId,
  }) async {
    final since = await _reseedAckDao.lastAck(circleDirId);
    return _shareService.reseedRequesters(groupId, circleDirId, since: since);
  }

  @override
  Future<void> reseedCircleBook({
    required String groupId,
    required String circleDirId,
    required String myNpub,
  }) async {
    await _uploadWithRetry(myNpub, groupId, circleDirId);
    await _reseedAckDao.ack(circleDirId);
  }

  @override
  Stream<bool> watchHasUnreadAdminActions(
    String ownerNpub,
    String circleDirId,
  ) {
    return _cheersDao.watchHasUnreadAdminActions(ownerNpub, circleDirId);
  }

  @override
  Future<void> markAdminActionsAsRead(String ownerNpub, String circleDirId) {
    return _cheersDao.markAdminActionsAsRead(ownerNpub, circleDirId);
  }
}
