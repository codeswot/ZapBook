import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/core/extensions/string_extension.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/circle_store_service.dart';
import 'package:zapbook/core/services/contact_service.dart';
import 'package:zapbook/core/data/dao/cheers_dao.dart';
import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';

abstract interface class CheersDataSource {
  Stream<List<CheersActivity>> watchActivities();
  Future<void> sendZap(String activityId, int amount, String reactionType);
}

final _log = logging.Logger('CheersDataSource');

@LazySingleton(as: CheersDataSource)
class CheersDataSourceImpl implements CheersDataSource {
  CheersDataSourceImpl(
    this._circleStore,
    this._identityLocal,
    this._cheersDao,
    this._contactService,
  );

  final CircleStoreService _circleStore;
  final IdentityLocalDataSource _identityLocal;
  final CheersDao _cheersDao;
  final ContactService _contactService;

  @override
  Stream<List<CheersActivity>> watchActivities() {
    return _cheersDao.watchActivities().asyncMap((activities) async {
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
  }

  @override
  Future<void> sendZap(
    String activityId,
    int amount,
    String reactionType,
  ) async {
    final npub = await _identityLocal.readNpub();
    if (npub == null || npub.isEmpty) return;

    try {} catch (error, stack) {
      _log.warning('cheer broadcast failed', error, stack);
    }
  }
}
