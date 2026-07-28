import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/data/database/dao/book_highlights_dao.dart';
import 'package:zapbook/core/data/database/dao/cheers_dao.dart';
import 'package:zapbook/core/data/database/dao/circle_progress_dao.dart';
import 'package:zapbook/core/data/infrastructure/marmot_sync_service.dart';
import 'package:zapbook/core/data/infrastructure/message_router_service.dart';
import 'package:zapbook/core/domain/entities/app_message.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';

class MockMarmotSyncService extends Mock implements MarmotSyncService {}

class MockCheersDao extends Mock implements CheersDao {}

class MockCircleProgressDao extends Mock implements CircleProgressDao {}

class MockBookHighlightsDao extends Mock implements BookHighlightsDao {}

class MockIdentityLocalDataSource extends Mock
    implements IdentityLocalDataSource {}

class MockMarmot extends Mock implements Marmot {}

class MockMarmotMessage extends Mock implements MarmotMessage {}

class FakeHighlightRecord extends Fake implements HighlightRecord {}

void main() {
  late MockMarmotSyncService mockMarmotSync;
  late MockCheersDao mockCheersDao;
  late MockCircleProgressDao mockCircleProgressDao;
  late MockBookHighlightsDao mockBookHighlightsDao;
  late MockIdentityLocalDataSource mockIdentity;
  late MockMarmot mockMarmot;
  late StreamController<MarmotMessage> messageController;
  late MessageRouterService service;

  setUpAll(() {
    registerFallbackValue(FakeHighlightRecord());
  });

  setUp(() {
    mockMarmotSync = MockMarmotSyncService();
    mockCheersDao = MockCheersDao();
    mockCircleProgressDao = MockCircleProgressDao();
    mockBookHighlightsDao = MockBookHighlightsDao();
    mockIdentity = MockIdentityLocalDataSource();
    mockMarmot = MockMarmot();
    messageController = StreamController<MarmotMessage>.broadcast();

    when(
      () => mockMarmotSync.onMessage,
    ).thenAnswer((_) => messageController.stream);
    when(() => mockBookHighlightsDao.upsert(any())).thenAnswer((_) async {});
    when(
      () => mockBookHighlightsDao.softDelete(any()),
    ).thenAnswer((_) async {});

    service = MessageRouterService(
      mockMarmotSync,
      mockCheersDao,
      mockCircleProgressDao,
      mockBookHighlightsDao,
      mockIdentity,
      mockMarmot,
    );
  });

  tearDown(() {
    service.dispose();
    messageController.close();
  });

  MockMarmotMessage buildMessage(Map<String, dynamic> payload) {
    final mock = MockMarmotMessage();
    when(() => mock.id).thenReturn('event1');
    when(() => mock.senderNpub).thenReturn('npub1sender');
    when(() => mock.groupId).thenReturn('group1');
    when(() => mock.timestampSecs).thenReturn(1700000000);
    when(() => mock.payloadJson).thenReturn(jsonEncode(payload));
    return mock;
  }

  test('a shared highlight is upserted into BookHighlightsDao', () async {
    messageController.add(
      buildMessage({
        'type': AppMessageTypes.highlightShared,
        'id': 'h1',
        'bookId': 'book1',
        'pageNumber': 4,
        'spans': [
          {'originalBlockIndex': 0, 'startOffset': 0, 'endOffset': 5},
        ],
        'quoteSnapshot': 'quote',
        'note': 'a note',
        'deleted': false,
        'sharedAtMs': 1700000000000,
      }),
    );

    await pumpEventQueue();

    final captured =
        verify(() => mockBookHighlightsDao.upsert(captureAny())).captured.single
            as HighlightRecord;

    expect(captured.id, 'h1');
    expect(captured.bookId, 'book1');
    expect(captured.ownerNpub, 'npub1sender');
    expect(captured.visibility, 'circle');
    expect(captured.groupId, 'group1');
    expect(captured.pageNumber, 4);
    expect(captured.quoteSnapshot, 'quote');
    expect(captured.note, 'a note');
    verifyNever(() => mockBookHighlightsDao.softDelete(any()));
  });

  test('a highlight-shared tombstone soft-deletes the local record', () async {
    messageController.add(
      buildMessage({
        'type': AppMessageTypes.highlightShared,
        'id': 'h1',
        'bookId': 'book1',
        'pageNumber': 4,
        'spans': <Map<String, dynamic>>[],
        'quoteSnapshot': 'quote',
        'note': null,
        'deleted': true,
        'sharedAtMs': 1700000000000,
      }),
    );

    await pumpEventQueue();

    verify(() => mockBookHighlightsDao.softDelete('h1')).called(1);
    verifyNever(() => mockBookHighlightsDao.upsert(any()));
  });

  test('a highlight-shared message with no id is ignored', () async {
    messageController.add(
      buildMessage({
        'type': AppMessageTypes.highlightShared,
        'bookId': 'book1',
        'pageNumber': 4,
        'spans': <Map<String, dynamic>>[],
        'quoteSnapshot': 'quote',
        'deleted': false,
      }),
    );

    await pumpEventQueue();

    verifyNever(() => mockBookHighlightsDao.upsert(any()));
    verifyNever(() => mockBookHighlightsDao.softDelete(any()));
  });
}
