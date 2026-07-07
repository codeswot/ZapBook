import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ndk/ndk.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:zapbook/core/services/milestone_service.dart';
import 'package:zapbook/core/services/decoded_message_cache.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';

class MockMarmot extends Mock implements Marmot {}

class MockNdk extends Mock implements Ndk {}

class MockIdentityLocalDataSource extends Mock
    implements IdentityLocalDataSource {}

class MockDecodedMessageCache extends Mock implements DecodedMessageCache {}

class FakeMarmotMessage extends Fake implements MarmotMessage {
  @override
  String? get payloadJson =>
      '{"type": "zapbook.book.milestone", "book_id": "book1"}';
  @override
  String get id => 'msg1';
  @override
  String get senderNpub => 'npub_sender';

  DateTime get timestamp => DateTime.now();
  @override
  String get groupId => 'group1';
  @override
  int get timestampSecs => DateTime.now().millisecondsSinceEpoch ~/ 1000;
}

void main() {
  late MockMarmot marmot;
  late MockNdk ndk;
  late MockIdentityLocalDataSource identity;
  late MockDecodedMessageCache cache;
  late MilestoneService service;

  setUp(() {
    marmot = MockMarmot();
    ndk = MockNdk();
    identity = MockIdentityLocalDataSource();
    cache = MockDecodedMessageCache();

    when(() => identity.readNpub()).thenAnswer((_) async => 'npub_self');
    when(() => marmot.listGroups()).thenAnswer((_) async => []);

    service = MilestoneService(marmot, ndk, identity, cache);
  });

  test('progressOf returns null initially', () {
    expect(service.progressOf('book1'), isNull);
  });

  test('membersOf returns empty initially', () {
    expect(service.membersOf('book1'), isEmpty);
  });

  test('loadMembers handles exceptions silently', () async {
    when(() => marmot.getMessages(any())).thenThrow(Exception('test'));
    final result = await service.loadMembers('book1');
    expect(result, isEmpty);
  });

  test('ingestMessage handles valid milestone', () {
    final msg = FakeMarmotMessage();
    when(() => cache.get(msg)).thenReturn({
      'circleBookId': 'book1',
      'type': 'zapbook.book.milestone',
      'payload': {
        'book_id': 'book1',
        'chapter_index': 1,
        'page_index': 5,
        'page_count': 100,
        'started_at': DateTime.now().millisecondsSinceEpoch,
        'last_read_at': DateTime.now().millisecondsSinceEpoch,
        'words_read': 500,
        'milestone_type': 'page',
      },
    });

    service.ingestMessage(msg);
  });
}
