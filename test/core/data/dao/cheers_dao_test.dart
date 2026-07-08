import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/core/data/app_database.dart';
import 'package:zapbook/core/data/dao/cheers_dao.dart';
import 'package:zapbook/core/domain/entities/cheers_activity_message.dart';

void main() {
  late Directory tempDir;
  late AppDatabase db;
  late CheersDao store;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('cheers_dao_test');
    db = AppDatabase.forPath('${tempDir.path}/app.db');
    store = CheersDao(db);
  });

  tearDown(() {
    db.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  CheersActivityMessage createActivity(String id, int timestampMillis) {
    return CheersActivityMessage(
      id: id,
      actorNpub: 'npub1',

      activityDescription: 'Shared a book',
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMillis),
      type: 'cheer',
      isUnread: false,
      thumbsUpCount: 1,
      clapCount: 0,
      fireCount: 0,
      rocketCount: 0,
      trophyCount: 0,
    );
  }

  final testActivity = createActivity('act1', 1000);

  test('saveActivity and loadActivities works', () async {
    await store.saveActivity(testActivity);

    final activities = await store.loadActivities();
    expect(activities.length, 1);
    expect(activities.first.id, 'act1');
    expect(activities.first.type, 'cheer');
  });

  test('watchActivities emits on save', () async {
    final stream = store.watchActivities();

    final nextUpdate = stream.skip(1).first;
    await store.saveActivity(testActivity);

    final activities = await nextUpdate;
    expect(activities.length, 1);
    expect(activities.first.id, 'act1');
  });

  test('loadActivities sorts by timestamp desc', () async {
    final act2 = createActivity('act2', 2000);
    final act3 = createActivity('act3', 500);

    await store.saveActivity(testActivity);
    await store.saveActivity(act2);
    await store.saveActivity(act3);

    final activities = await store.loadActivities();
    expect(activities.length, 3);
    expect(activities[0].id, 'act2');
    expect(activities[1].id, 'act1');
    expect(activities[2].id, 'act3');
  });

  test('loadActivities respects limit', () async {
    for (var i = 0; i < 5; i++) {
      await store.saveActivity(createActivity('act$i', 1000 + i));
    }

    final activities = await store.loadActivities(limit: 2);
    expect(activities.length, 2);

    expect(activities[0].id, 'act4');
    expect(activities[1].id, 'act3');
  });
}
