import 'dart:async';
import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:marmot_dart/marmot_dart.dart';
import 'package:ndk/ndk.dart';
import 'package:zapbook/core/domain/book_group_naming.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/contact_service.dart';
import 'package:zapbook/core/services/decoded_message_cache.dart';
import 'package:zapbook/core/services/milestone_service.dart';
import 'package:zapbook/core/services/nostr_service.dart';
import 'package:zapbook/core/services/profile_meta_generator.dart';
import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';

abstract interface class CheersDataSource {
  Stream<List<CheersActivity>> watchActivities();
  Future<void> sendZap(String activityId, int amount, String reactionType);
}

final _log = logging.Logger('CheersDataSource');

const _cheerType = 'zapbook.cheer';

@LazySingleton(as: CheersDataSource)
class CheersDataSourceImpl implements CheersDataSource {
  CheersDataSourceImpl(
    this._marmot,
    this._ndk,
    this._identityLocal,
    this._milestone,
    this._contacts,
    this._cache,
  );

  final Marmot _marmot;
  final Ndk _ndk;
  final IdentityLocalDataSource _identityLocal;
  final MilestoneService _milestone;
  final ContactService _contacts;
  final DecodedMessageCache _cache;

  final _changeController = StreamController<void>.broadcast();

  @override
  Stream<List<CheersActivity>> watchActivities() {
    final controller = StreamController<List<CheersActivity>>.broadcast();
    int? lastSignature;
    var lastBase = <CheersActivity>[];
    var lastMyNpub = '';

    Future<void> emitEnriched() async {
      final actorNpubs = {for (final a in lastBase) a.actorNpub}.toList();
      await _contacts.prime(actorNpubs);
      final enriched = [
        for (final a in lastBase)
          a.actorNpub == lastMyNpub ? a : _withMetadata(a),
      ];
      if (!controller.isClosed) controller.add(enriched);
    }

    void reload({bool force = false}) async {
      try {
        final myNpub = await _identityLocal.readNpub() ?? '';
        final groups = await _marmot.listGroups();
        final bookGroups = groups
            .where((group) => BookGroupNaming.matches(group.name))
            .toList();
        final perGroupMessages = await Future.wait(
          bookGroups.map((group) => _marmot.getMessages(group.id)),
        );

        final signature = _signatureFor(perGroupMessages);
        if (!force && signature == lastSignature) return;
        lastSignature = signature;

        final cutoffSecs = DateTime.now().millisecondsSinceEpoch ~/ 1000 - 3600;
        final activities = <CheersActivity>[];
        for (var i = 0; i < bookGroups.length; i++) {
          activities.addAll(
            _groupActivities(
              bookGroups[i],
              perGroupMessages[i],
              myNpub,
              cutoffSecs,
            ),
          );
        }
        activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        lastBase = activities;
        lastMyNpub = myNpub;
        await emitEnriched();
      } catch (error, stack) {
        _log.warning('activities reload failed', error, stack);
      }
    }

    reload(force: true);

    final timer = Timer.periodic(const Duration(seconds: 5), (_) => reload());
    final sub = _changeController.stream.listen((_) => reload(force: true));
    final metaSub = _contacts.metadataChanges.listen((_) {
      if (lastBase.isNotEmpty) emitEnriched();
    });

    controller.onCancel = () {
      timer.cancel();
      sub.cancel();
      metaSub.cancel();
      controller.close();
    };

    return controller.stream;
  }

  CheersActivity _withMetadata(CheersActivity activity) {
    final contact = _contacts.contactFor(activity.actorNpub);
    final name = (contact.displayName?.trim().isNotEmpty ?? false)
        ? contact.displayName!.trim()
        : activity.actorName;
    final avatar = (contact.picture?.trim().isNotEmpty ?? false)
        ? contact.picture
        : activity.actorAvatar;
    return activity.copyWith(actorName: name, actorAvatar: avatar);
  }

  int _signatureFor(List<List<MarmotMessage>> perGroupMessages) {
    var signature = 17;
    for (final messages in perGroupMessages) {
      signature = signature * 31 + messages.length;
    }
    return signature;
  }

  @override
  Future<void> sendZap(
    String activityId,
    int amount,
    String reactionType,
  ) async {
    final npub = await _identityLocal.readNpub();
    if (npub == null || npub.isEmpty) return;

    final parts = activityId.split(':');
    if (parts.length < 2) return;
    final groupId = parts[0];
    final messageId = parts[1];

    final payload = {
      'type': _cheerType,
      'activityId': messageId,
      'amount': amount,
      'reactionType': reactionType,
    };

    await _marmot.sendStructured(npub, groupId, payload);

    _changeController.add(null);

    try {
      final messages = await _marmot.getMessages(groupId);
      Map<String, dynamic>? latestCheer;
      for (final msg in messages) {
        final decoded = _cache.get(msg);
        if (decoded == null) continue;
        if (decoded['type'] == _cheerType &&
            decoded['activityId'] == messageId &&
            decoded['reactionType'] == reactionType) {
          latestCheer = decoded;
        }
      }

      if (latestCheer != null) {
        final groups = await _marmot.listGroups();
        MarmotGroup? match;
        for (final g in groups) {
          if (g.id == groupId) {
            match = g;
            break;
          }
        }
        if (match != null) {
          final eventJson = jsonEncode({
            'id': latestCheer['id'],
            'pubkey': latestCheer['pubkey'] ?? npub,
            'created_at':
                latestCheer['created_at'] ??
                (DateTime.now().millisecondsSinceEpoch ~/ 1000),
            'kind': 445,
            'tags': [
              ['h', match.nostrGroupId],
            ],
            'content': jsonEncode(latestCheer),
            'sig': latestCheer['sig'],
          });

          final map = jsonDecode(eventJson) as Map<String, dynamic>;
          final tags = (map['tags'] as List)
              .map((tag) => (tag as List).map((e) => e.toString()).toList())
              .toList();
          String pubKey = map['pubkey'] as String;
          if (pubKey.startsWith('npub')) {
            pubKey = Nip19.decode(pubKey);
          }
          final nipEvent = Nip01Event(
            id: map['id'] as String?,
            pubKey: pubKey,
            kind: (map['kind'] as num).toInt(),
            tags: tags,
            content: map['content'] as String,
            sig: map['sig'] as String?,
            createdAt: (map['created_at'] as num).toInt(),
          );
          _ndk.broadcast.broadcast(
            nostrEvent: nipEvent,
            specificRelays: NostrService.broadcastRelays,
          );
        }
      }
    } catch (error, stack) {
      _log.warning('cheer broadcast failed', error, stack);
    }
  }

  List<CheersActivity> _groupActivities(
    MarmotGroup group,
    List<MarmotMessage> messages,
    String myNpub,
    int cutoffSecs,
  ) {
    final activities = <CheersActivity>[];

    {
      var bookTitle = 'Unknown Book';
      final cheers = <Map<String, dynamic>>[];
      final cheerEntries = <Map<String, dynamic>>[];
      final nudges = <Map<String, dynamic>>[];
      final resolvedNudgeIds = <String>{};
      final seenNudgeIds = <String>{};
      final readyForMe = <Map<String, dynamic>>{};

      for (final msg in messages) {
        final decoded = _cache.get(msg);
        if (decoded == null) continue;
        switch (decoded['type']) {
          case 'zapbook.book.milestone':
          case 'zapbook.book.completed':
            _milestone.ingestMessage(msg);
          case 'zapbook.book.meta':
            bookTitle = decoded['title'] as String? ?? bookTitle;
          case _cheerType:
            final entry = {
              'activityId': decoded['activityId'],
              'reactionType': decoded['reactionType'],
              'amount': (decoded['amount'] as num?)?.toInt() ?? 0,
              'senderNpub': msg.senderNpub,
              'timestampSecs': msg.timestampSecs.toInt(),
            };
            cheers.add(entry);
            cheerEntries.add(entry);
          case 'zapbook.zap.nudge':
            nudges.add(decoded);
          case 'zapbook.zap.ready':
            final id = decoded['nudgeId'] as String? ?? '';
            resolvedNudgeIds.add(id);
            if (decoded['toNpub'] == myNpub) readyForMe.add(decoded);
        }
      }

      for (final event in _milestone.eventsForGroup(group.id)) {
        final isMine = event.npub == myNpub;
        final pctStr = event.progressPct > 0
            ? ' (${event.progressPct.toStringAsFixed(1)}%)'
            : '';
        final description = event.completed
            ? 'Finished the book'
            : 'Milestone ${event.milestoneIdx + 1}: page ${event.currentPage}'
                  '$pctStr';
        final fallback = ProfileMetaGenerator.generate(seed: event.npub);

        var thumbsUp = 0;
        var claps = 0;
        var fire = 0;
        var rocket = 0;
        var trophy = 0;
        for (final cheer in cheers) {
          if (cheer['activityId'] != event.id) continue;
          switch (cheer['reactionType']) {
            case 'like':
              thumbsUp++;
            case 'clap':
              claps++;
            case 'fire':
              fire++;
            case 'rocket':
              rocket++;
            case 'trophy':
              trophy++;
          }
        }

        activities.add(
          CheersActivity(
            id: '${event.groupId}:${event.id}',
            actorNpub: event.npub,
            actorName: isMine ? 'You' : fallback.displayName,
            actorAvatar: fallback.avatar,
            bookTitle: bookTitle,
            bookId: event.bookId,
            activityDescription: description,
            timestamp: event.timestamp,
            type: isMine ? 'mine' : 'milestone',
            isUnread:
                !isMine &&
                event.timestamp.millisecondsSinceEpoch ~/ 1000 > cutoffSecs,
            thumbsUpCount: thumbsUp,
            clapCount: claps,
            fireCount: fire,
            rocketCount: rocket,
            trophyCount: trophy,
          ),
        );
      }

      for (final cheer in cheerEntries) {
        final senderNpub = cheer['senderNpub'] as String;
        final isFromMe = senderNpub == myNpub;
        final reactionType = cheer['reactionType'] as String;
        final reactionEmoji = _reactionEmoji(reactionType);
        final amount = cheer['amount'] as int;
        final activityId = cheer['activityId'] as String;

        final targetEvent = _findMilestoneEvent(group.id, activityId);
        final targetDesc = targetEvent != null
            ? '${targetEvent.completed ? "Finished" : "Milestone ${targetEvent.milestoneIdx + 1}"} in $bookTitle'
            : 'activity in $bookTitle';

        final gen = ProfileMetaGenerator.generate(seed: senderNpub);
        final senderName = isFromMe ? 'You' : gen.displayName;

        activities.add(
          CheersActivity(
            id: '${group.id}:${cheer['activityId']}:${cheer['senderNpub']}:${cheer['reactionType']}:${cheer['timestampSecs']}',
            actorNpub: senderNpub,
            actorName: senderName,
            actorAvatar: isFromMe ? null : gen.avatar,
            bookTitle: bookTitle,
            bookId: group.id,
            activityDescription: isFromMe
                ? '$reactionEmoji You zapped $amount sats for $targetDesc'
                : '$reactionEmoji $senderName zapped $amount sats for $targetDesc',
            timestamp: DateTime.fromMillisecondsSinceEpoch(
              (cheer['timestampSecs'] as int) * 1000,
            ),
            type: 'zap',
            isUnread: false,
            zapAmount: amount,
            zapReaction: reactionType,
            zapTargetId: activityId,
            zapTargetDescription: targetDesc,
            zapRecipientNpub: targetEvent?.npub,
          ),
        );
      }

      for (final nudge in nudges) {
        if (nudge['toNpub'] != myNpub) continue;
        final nudgeId = nudge['nudgeId'] as String? ?? '';
        if (nudgeId.isEmpty || resolvedNudgeIds.contains(nudgeId)) continue;
        final fromNpub = nudge['fromNpub'] as String? ?? '';
        final gen = ProfileMetaGenerator.generate(seed: fromNpub);
        final fromName = nudge['fromName'] as String? ?? gen.displayName;
        final createdMs =
            (nudge['createdAtMs'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch;
        activities.add(
          CheersActivity(
            id: '${group.id}:$nudgeId',
            actorNpub: fromNpub,
            actorName: fromName,
            actorAvatar: gen.avatar,
            bookTitle: bookTitle,
            activityDescription:
                '$fromName wants to zap you, but your receiving address '
                "isn't set. Set it in your profile, then tap to buzz them.",
            timestamp: DateTime.fromMillisecondsSinceEpoch(createdMs),
            type: 'zap_nudge',
            isUnread: true,
            nudgeId: nudgeId,
          ),
        );
      }

      for (final ready in readyForMe) {
        final nudgeId = ready['nudgeId'] as String? ?? '';
        if (seenNudgeIds.contains(nudgeId)) continue;
        seenNudgeIds.add(nudgeId);
        final fromNpub = ready['fromNpub'] as String? ?? '';
        final gen = ProfileMetaGenerator.generate(seed: fromNpub);
        final fromName = ready['fromName'] as String? ?? gen.displayName;
        final createdMs =
            (ready['createdAtMs'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch;
        activities.add(
          CheersActivity(
            id: '${group.id}:$nudgeId:ready',
            actorNpub: fromNpub,
            actorName: fromName,
            actorAvatar: gen.avatar,
            bookTitle: bookTitle,
            activityDescription: '$fromName set up their wallet — zap them!',
            timestamp: DateTime.fromMillisecondsSinceEpoch(createdMs),
            type: 'zap_ready',
            isUnread: true,
            nudgeId: nudgeId,
          ),
        );
      }
    }

    return activities;
  }

  static String _reactionEmoji(String reactionType) {
    switch (reactionType) {
      case 'clap':
        return '👏';
      case 'fire':
        return '🔥';
      case 'rocket':
        return '🚀';
      case 'trophy':
        return '🏆';
      default:
        return '👍';
    }
  }

  MilestoneEvent? _findMilestoneEvent(String groupId, String eventId) {
    for (final event in _milestone.eventsForGroup(groupId)) {
      if (event.id == eventId) return event;
    }
    return null;
  }
}
