import 'dart:async';
import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:ndk/ndk.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/milestone_service.dart';
import 'package:zapbook/core/services/nostr_service.dart';
import 'package:zapbook/core/services/profile_meta_generator.dart';
import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';

abstract interface class CheersDataSource {
  Stream<List<CheersActivity>> watchActivities();
  Future<void> sendZap(String activityId, int amount, String reactionType);
}

@LazySingleton(as: CheersDataSource)
class CheersDataSourceImpl implements CheersDataSource {
  CheersDataSourceImpl(
    this._marmot,
    this._ndk,
    this._identityLocal,
    this._milestone,
  );

  final Marmot _marmot;
  final Ndk _ndk;
  final IdentityLocalDataSource _identityLocal;
  final MilestoneService _milestone;

  final _changeController = StreamController<void>.broadcast();

  @override
  Stream<List<CheersActivity>> watchActivities() {
    final controller = StreamController<List<CheersActivity>>.broadcast();

    void reload() async {
      try {
        final data = await _fetchActivities();
        if (!controller.isClosed) {
          controller.add(data);
        }
      } catch (_) {}
    }

    reload();

    final timer = Timer.periodic(const Duration(seconds: 5), (_) => reload());
    final sub = _changeController.stream.listen((_) => reload());

    controller.onCancel = () {
      timer.cancel();
      sub.cancel();
      controller.close();
    };

    return controller.stream;
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
      'type': 'zapbook.cheer',
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
        final raw = msg.payloadJson;
        if (raw == null || raw.isEmpty) continue;
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic> &&
              decoded['type'] == 'zapbook.cheer' &&
              decoded['activityId'] == messageId &&
              decoded['reactionType'] == reactionType) {
            latestCheer = decoded;
          }
        } catch (_) {}
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
    } catch (_) {}
  }

  Future<List<CheersActivity>> _fetchActivities() async {
    final myNpub = await _identityLocal.readNpub() ?? '';
    final groups = await _marmot.listGroups();
    final cutoffSecs = DateTime.now().millisecondsSinceEpoch ~/ 1000 - 3600;

    final bookGroups = groups
        .where((group) => group.name.startsWith('zapbook-book-'))
        .toList();
    final perGroup = await Future.wait(
      bookGroups.map((group) => _groupActivities(group, myNpub, cutoffSecs)),
    );
    final activities = perGroup
        .expand((groupActivities) => groupActivities)
        .toList();

    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return activities;
  }

  Future<List<CheersActivity>> _groupActivities(
    MarmotGroup group,
    String myNpub,
    int cutoffSecs,
  ) async {
    final activities = <CheersActivity>[];
    final messages = await _marmot.getMessages(group.id);

    {
      var bookTitle = 'Unknown Book';
      final cheers = <Map<String, dynamic>>[];
      final nudges = <Map<String, dynamic>>[];
      final resolvedNudgeIds = <String>{};
      final seenNudgeIds = <String>{};
      final readyForMe = <Map<String, dynamic>>{};

      for (final msg in messages) {
        final raw = msg.payloadJson;
        if (raw == null || raw.isEmpty) continue;
        try {
          final decoded = jsonDecode(raw);
          if (decoded is! Map<String, dynamic>) continue;
          switch (decoded['type']) {
            case 'zapbook.book.milestone':
            case 'zapbook.book.completed':
              _milestone.ingestMessage(msg);
            case 'zapbook.book.meta':
              bookTitle = decoded['title'] as String? ?? bookTitle;
            case 'zapbook.cheer':
              cheers.add({
                'activityId': decoded['activityId'],
                'reactionType': decoded['reactionType'],
              });
            case 'zapbook.zap.nudge':
              nudges.add(decoded);
            case 'zapbook.zap.ready':
              final id = decoded['nudgeId'] as String? ?? '';
              resolvedNudgeIds.add(id);
              if (decoded['toNpub'] == myNpub) readyForMe.add(decoded);
          }
        } catch (_) {}
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
}
