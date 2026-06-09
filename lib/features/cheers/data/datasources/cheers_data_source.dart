import 'dart:async';
import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:ndk/ndk.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
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
  );

  final Marmot _marmot;
  final Ndk _ndk;
  final IdentityLocalDataSource _identityLocal;

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

    await _marmot.sendStructured(
      npub,
      groupId,
      payload,
    );

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
            'created_at': latestCheer['created_at'] ??
                (DateTime.now().millisecondsSinceEpoch ~/ 1000),
            'kind': 445,
            'tags': [
              ['h', match.nostrGroupId]
            ],
            'content': jsonEncode(latestCheer),
            'sig': latestCheer['sig'],
          });

          final map = jsonDecode(eventJson) as Map<String, dynamic>;
          final tags = (map['tags'] as List)
              .map((tag) => (tag as List).map((e) => e.toString()).toList())
              .toList();
          final nipEvent = Nip01Event(
            id: map['id'] as String?,
            pubKey: map['pubkey'] as String,
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
    final activities = <CheersActivity>[];

    for (final group in groups) {
      if (!group.name.startsWith('zapbook-book-')) continue;

      final messages = await _marmot.getMessages(group.id);

      String bookTitle = 'Unknown Book';
      for (final msg in messages) {
        final raw = msg.payloadJson;
        if (raw == null || raw.isEmpty) continue;
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic> &&
              decoded['type'] == 'zapbook.book.meta') {
            bookTitle = decoded['title'] as String? ?? 'Unknown Book';
            break;
          }
        } catch (_) {}
      }

      final activityMsgs = <MarmotMessage>[];
      final cheersMsgs = <Map<String, dynamic>>[];

      for (final msg in messages) {
        final raw = msg.payloadJson;
        if (raw == null || raw.isEmpty) continue;
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            final type = decoded['type'];
            if (type == 'zapbook.book.milestone' ||
                type == 'zapbook.book.completed') {
              activityMsgs.add(msg);
            } else if (type == 'zapbook.cheer') {
              cheersMsgs.add({
                'activityId': decoded['activityId'],
                'reactionType': decoded['reactionType'],
                'amount': decoded['amount'],
              });
            }
          }
        } catch (_) {}
      }

      final seenIds = <String>{};
      for (final msg in activityMsgs) {
        final messageId = msg.id;
        if (seenIds.contains(messageId)) continue;
        seenIds.add(messageId);

        final raw = msg.payloadJson!;
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final isCompleted = decoded['type'] == 'zapbook.book.completed';
        String description;
        if (isCompleted) {
          description = 'Finished the book';
        } else {
          final milestoneIdx =
              (decoded['milestone_idx'] as num?)?.toInt() ?? 0;
          final page = (decoded['current_page'] as num?)?.toInt() ?? 1;
          final pct = (decoded['progress_pct'] as num?)?.toDouble();
          final pctStr = pct != null ? ' (${pct.toStringAsFixed(1)}%)' : '';
          description = 'Milestone ${milestoneIdx + 1}: page $page$pctStr';
        }
        final senderNpub = msg.senderNpub;

        final fallback = ProfileMetaGenerator.generate(seed: senderNpub);
        final actorName = senderNpub == myNpub ? 'You' : fallback.displayName;
        final actorAvatar = fallback.avatar;

        var thumbsUp = 0;
        var claps = 0;
        var fire = 0;
        var rocket = 0;
        var trophy = 0;

        for (final cheer in cheersMsgs) {
          if (cheer['activityId'] == messageId) {
            final type = cheer['reactionType'] as String?;
            if (type == 'like') thumbsUp++;
            if (type == 'clap') claps++;
            if (type == 'fire') fire++;
            if (type == 'rocket') rocket++;
            if (type == 'trophy') trophy++;
          }
        }

        activities.add(
          CheersActivity(
            id: '${group.id}:$messageId',
            actorNpub: senderNpub,
            actorName: actorName,
            actorAvatar: actorAvatar,
            bookTitle: bookTitle,
            activityDescription: description,
            timestamp: DateTime.fromMillisecondsSinceEpoch(
              msg.timestampSecs.toInt() * 1000,
            ),
            type: senderNpub == myNpub ? 'mine' : 'milestone',
            isUnread: senderNpub != myNpub &&
                msg.timestampSecs.toInt() >
                    (DateTime.now().millisecondsSinceEpoch ~/ 1000 - 3600),
            thumbsUpCount: thumbsUp,
            clapCount: claps,
            fireCount: fire,
            rocketCount: rocket,
            trophyCount: trophy,
          ),
        );
      }
    }

    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return activities;
  }
}
