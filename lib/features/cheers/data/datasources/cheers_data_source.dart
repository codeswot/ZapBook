import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/core/extensions/string_extension.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/data/infrastructure/circle_store_service.dart';
import 'package:zapbook/core/data/infrastructure/contact_service.dart';
import 'package:zapbook/core/data/database/dao/cheers_dao.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/data/infrastructure/zap_service.dart';
import 'package:zapbook/core/domain/entities/zap_status.dart';
import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';

import 'package:zapbook/core/domain/entities/cheers_activity_type.dart';
import 'package:zapbook/core/data/database/dao/zap_sats_earnings_dao.dart';
import 'package:ndk/ndk.dart';
import 'package:zapbook/core/data/infrastructure/clipboard_service.dart';
import 'package:zapbook/core/data/infrastructure/nostr_service.dart';
import 'package:zapbook/core/data/infrastructure/zap_nudge_service.dart';

abstract interface class CheersDataSource {
  Stream<List<CheersActivity>> watchActivities();

  Future<ZapStatus> sendZap({
    required CheersActivity activity,
    required ZapGesture gesture,
    required int amount,
    String? comment,
  });

  Future<void> sendNudge({required String groupId, required String toNpub});

  Future<void> sendNudgeReady({
    required String groupId,
    required String nudgeId,
    required String toNpub,
  });

  Future<String?> lookupLud16(String pubkey);

  Future<String?> getMyPubkey();

  Future<void> copyText(String text);
}

final _log = logging.Logger('CheersDataSource');

@LazySingleton(as: CheersDataSource)
class CheersDataSourceImpl implements CheersDataSource {
  CheersDataSourceImpl(
    this._circleStore,
    this._identityLocal,
    this._cheersDao,
    this._contactService,
    this._zapService,
    this._nudgeService,
    this._nostrService,
    this._clipboardService,
  );

  final CircleStoreService _circleStore;
  final IdentityLocalDataSource _identityLocal;
  final CheersDao _cheersDao;
  final ContactService _contactService;
  final ZapService _zapService;
  final ZapNudgeService _nudgeService;
  final NostrService _nostrService;
  final ClipboardService _clipboardService;

  @override
  Stream<List<CheersActivity>> watchActivities() {
    return Stream.fromFuture(_identityLocal.readNpub()).asyncExpand((myNpub) {
      final owner = myNpub ?? '';
      return _cheersDao.watchActivities(owner).asyncMap((activities) async {
        if (activities.isEmpty) return const <CheersActivity>[];

      final myNpub = await _identityLocal.readNpub();
      final circlesMap = {for (final c in _circleStore.currentCircles) c.id: c};

      final uniqueNpubs = {
        for (final msg in activities) ...[
          if (msg.actorNpub.isNpub == true) msg.actorNpub,
          if (msg.zapRecipientNpub?.isNpub == true) msg.zapRecipientNpub!,
        ],
        if (myNpub != null && myNpub.isNpub == true) myNpub,
      };

      final contactsMap = <String, Contact>{};

      await Future.wait(
        uniqueNpubs.map((npub) async {
          try {
            contactsMap[npub] = await _contactService.resolve(npub);
          } catch (_) {
            _log.warning('Failed to resolve contact for npub: $npub');
          }
        }),
      );

      return activities.map((msg) {
        final circle = circlesMap[msg.groupId];
        final senderContact = contactsMap[msg.actorNpub];
        final recipientContact = msg.zapRecipientNpub != null
            ? contactsMap[msg.zapRecipientNpub!]
            : null;

        final isMine = msg.actorNpub == myNpub;

        final recName = recipientContact?.displayName;
        final senderName = senderContact?.displayName;

        final finalActorName = isMine
            ? 'You'
            : (senderName != null && senderName.isNotEmpty
                  ? senderName
                  : 'Someone');

        final finalActorAvatar = isMine
            ? contactsMap[myNpub]?.picture ?? ''
            : senderContact?.picture ?? '';

        return CheersActivity(
          id: msg.id,
          groupId: circle?.id ?? msg.groupId ?? '',
          actorNpub: msg.actorNpub,
          otherPartyNpub: msg.zapRecipientNpub ?? '',
          targetId: msg.zapTargetId ?? '',
          targetDescription:
              msg.zapTargetDescription ?? msg.activityDescription,
          timestamp: msg.timestamp,
          type: msg.type,
          isUnread: msg.isUnread,
          isMine: isMine,
          nudgeId: msg.nudgeId,
          thumbsUpCount: msg.thumbsUpCount,
          clapCount: msg.clapCount,
          fireCount: msg.fireCount,
          rocketCount: msg.rocketCount,
          trophyCount: msg.trophyCount,
          zapAmount: msg.zapAmount,
          zapReaction: msg.zapReaction,
          bookCircleTitle: circle?.title,
          otherPartyName: recName != null && recName.isNotEmpty
              ? recName
              : msg.zapRecipientNpub?.toNpubShort() ?? '',
          otherPartyPicture: recipientContact?.picture ?? '',
          actorName: finalActorName,
          actorPicture: finalActorAvatar,
          bookId: msg.circleBookId,
        );
      }).toList();
    });
    });
  }

  @override
  Future<ZapStatus> sendZap({
    required CheersActivity activity,
    required ZapGesture gesture,
    required int amount,
    String? comment,
  }) async {
    final pubkey = Nip19.decode(activity.actorNpub);
    final lud16 = await lookupLud16(pubkey);

    if (lud16 == null || lud16.isEmpty) {
      return ZapStatus.failed;
    }

    final result = await _zapService.send(
      recipientLud16: lud16,
      recipientPubkey: pubkey,
      targetActivitytId: activity.targetId,
      gesture: gesture,
      customSats: amount,
      comment: comment,
      zapType: activity.type == CheersActivityType.milestone
          ? ZapType.milestone
          : ZapType.profile,
    );

    return _zapService.payZap(result);
  }

  @override
  Future<void> sendNudge({required String groupId, required String toNpub}) =>
      _nudgeService.nudge(groupId: groupId, toNpub: toNpub);

  @override
  Future<void> sendNudgeReady({
    required String groupId,
    required String nudgeId,
    required String toNpub,
  }) => _nudgeService.ready(groupId: groupId, nudgeId: nudgeId, toNpub: toNpub);

  @override
  Future<String?> lookupLud16(String pubkey) async {
    final cache = await _nostrService.getMetadata(pubkey);
    final cachedlud16 = cache?.lud16 ?? '';
    if (cachedlud16.isNotEmpty) {
      return cachedlud16;
    }
    final fresh = await _nostrService.getMetadata(pubkey, forceRefresh: true);
    return fresh?.lud16;
  }

  @override
  Future<String?> getMyPubkey() async {
    final npub = await _identityLocal.readNpub();
    if (npub == null || npub.isEmpty) return null;
    try {
      return Nip19.decode(npub);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> copyText(String text) async {
    _clipboardService.copy(text);
  }
}
