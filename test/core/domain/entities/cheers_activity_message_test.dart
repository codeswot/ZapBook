import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/domain/entities/cheers_activity_message.dart';
import 'package:zapbook/core/models/app_message.dart';
import 'package:zapbook/core/models/circle_member_progress.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'dart:convert';

class MockMarmotMessage extends Mock implements MarmotMessage {}

void main() {
  group('CheersActivityMessage', () {
    test('cheerFromProgress completed book', () {
      final next = const CircleMemberProgress(
        groupId: 'g1',
        pubKey: 'p1',
        bookId: 'b1',
        pageIndex: 10,
        progressPercentage: 1.0,
        updatedAt: 1000,
        completed: true,
      );

      final msg = CheersActivityMessage.cheerFromProgress(
        id: 'id1',
        actorNpub: 'actor',
        groupId: 'g1',
        timestampSecs: 1000,
        previous: null,
        next: next,
      );

      expect(msg, isNotNull);
      expect(msg!.type, 'milestone');
      expect(msg.activityDescription, 'Finished the book');
      expect(msg.isUnread, true);
    });

    test('cheerFromProgress milestone reached', () {
      final prev = const CircleMemberProgress(
        groupId: 'g1',
        pubKey: 'p1',
        bookId: 'b1',
        pageIndex: 5,
        progressPercentage: 0.5,
        updatedAt: 900,
        milestonesReached: 1,
      );
      final next = const CircleMemberProgress(
        groupId: 'g1',
        pubKey: 'p1',
        bookId: 'b1',
        pageIndex: 10,
        progressPercentage: 0.6,
        updatedAt: 1000,
        milestonesReached: 2,
      );

      final msg = CheersActivityMessage.cheerFromProgress(
        id: 'id1',
        actorNpub: 'actor',
        groupId: 'g1',
        timestampSecs: 1000,
        previous: prev,
        next: next,
      );

      expect(msg, isNotNull);
      expect(msg!.type, 'milestone');
      expect(msg.activityDescription, 'Milestone 2: page 10 (60.0%)');
    });

    test('cheerFromProgress returns null if nothing changed', () {
      final next = const CircleMemberProgress(
        groupId: 'g1',
        pubKey: 'p1',
        bookId: 'b1',
        pageIndex: 10,
        progressPercentage: 0.6,
        updatedAt: 1000,
        milestonesReached: 2,
      );

      final msg = CheersActivityMessage.cheerFromProgress(
        id: 'id1',
        actorNpub: 'actor',
        groupId: 'g1',
        timestampSecs: 1000,
        previous: next,
        next: next,
      );

      expect(msg, isNull);
    });

    MockMarmotMessage createMockMsg(String payloadJson) {
      final mock = MockMarmotMessage();
      when(() => mock.id).thenReturn('m1');
      when(() => mock.senderNpub).thenReturn('actor');
      when(() => mock.groupId).thenReturn('g1');
      when(() => mock.timestampSecs).thenReturn(1000);
      when(() => mock.payloadJson).thenReturn(payloadJson);
      return mock;
    }

    test('fromAppMessage with CheersMessage', () {
      final payload = jsonEncode({
        'type': AppMessageTypes.cheer,
        'message': 'Good job!',
        'clapCount': 2,
      });
      final appMsg = AppMessage.tryParse(createMockMsg(payload));
      expect(appMsg, isA<CheersMessage>());

      final msg = CheersActivityMessage.fromAppMessage(appMsg!);
      expect(msg, isNotNull);
      expect(msg!.type, 'cheer');
      expect(msg.activityDescription, 'Good job!');
      expect(msg.clapCount, 2);
    });

    test('fromAppMessage with ZapSentMessage', () {
      final payload = jsonEncode({
        'type': AppMessageTypes.zapSent,
        'description': 'Zapped you',
        'amount': 1000,
        'reaction': '⚡',
      });
      final appMsg = AppMessage.tryParse(createMockMsg(payload));
      expect(appMsg, isA<ZapSentMessage>());

      final msg = CheersActivityMessage.fromAppMessage(appMsg!);
      expect(msg, isNotNull);
      expect(msg!.type, 'zap');
      expect(msg.zapAmount, 1000);
      expect(msg.zapReaction, '⚡');
    });

    test('fromAppMessage with ZapNudgeMessage', () {
      final payload = jsonEncode({
        'type': AppMessageTypes.zapNudge,
        'nudgeId': 'n1',
      });
      final appMsg = AppMessage.tryParse(createMockMsg(payload));
      expect(appMsg, isA<ZapNudgeMessage>());

      final msg = CheersActivityMessage.fromAppMessage(appMsg!);
      expect(msg, isNotNull);
      expect(msg!.type, 'zap_nudge');
      expect(msg.nudgeId, 'n1');
    });

    test('fromAppMessage with ZapReadyMessage', () {
      final payload = jsonEncode({
        'type': AppMessageTypes.zapReady,
        'nudgeId': 'n1',
      });
      final appMsg = AppMessage.tryParse(createMockMsg(payload));
      expect(appMsg, isA<ZapReadyMessage>());

      final msg = CheersActivityMessage.fromAppMessage(appMsg!);
      expect(msg, isNotNull);
      expect(msg!.type, 'zap_ready');
      expect(msg.nudgeId, 'n1');
    });

    test('fromAppMessage with irrelevant message returns null', () {
      final payload = jsonEncode({'type': AppMessageTypes.bookMeta});
      final appMsg = AppMessage.tryParse(createMockMsg(payload));

      final msg = CheersActivityMessage.fromAppMessage(appMsg!);
      expect(msg, isNull);
    });
  });
}
