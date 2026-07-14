import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/core/data/database/app_database.dart';
import 'package:zapbook/core/data/database/dao/circle_progress_dao.dart';
import 'package:zapbook/core/models/circle_member_progress.dart';

void main() {
  late Directory tempDir;
  late AppDatabase db;
  late CircleProgressDao dao;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('circle_progress_dao_test');
    db = AppDatabase.forPath('${tempDir.path}/app.db');
    dao = CircleProgressDao(db);
  });

  tearDown(() {
    db.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  int idCounter = 0;
  CircleMemberProgress createProgress({
    String? id,
    required String groupId,
    required String bookId,
    required String pubKey,
    int pageIndex = 1,
    double progressPercentage = 10.0,
    int updatedAt = 1000,
    int milestonesReached = 0,
    bool completed = false,
  }) {
    idCounter++;
    return CircleMemberProgress(
      id: id ?? "dummy-id-$idCounter",
      groupId: groupId,
      pubKey: pubKey,
      bookId: bookId,
      pageIndex: pageIndex,
      progressPercentage: progressPercentage,
      updatedAt: updatedAt,
      milestonesReached: milestonesReached,
      completed: completed,
    );
  }

  test('upsertProgress and watchProgressByBook', () async {
    final stream = dao.watchProgressByBook(groupId: 'g1', bookId: 'b1');
    final nextEmission = stream.skip(1).first;

    final progress = createProgress(groupId: 'g1', bookId: 'b1', pubKey: 'p1');
    await dao.upsertProgress(progress);

    final results = await nextEmission;
    expect(results.length, 1);
    expect(results.first.pubKey, 'p1');
  });

  test('getProgress returns null for unknown', () async {
    final progress = await dao.getProgress(
      groupId: 'g1',
      bookId: 'b1',
      pubKey: 'p1',
    );
    expect(progress, isNull);
  });

  test(
    'upsertProgress updates existing record keeping max milestones',
    () async {
      final p1 = createProgress(
        groupId: 'g1',
        bookId: 'b1',
        pubKey: 'p1',
        milestonesReached: 2,
        updatedAt: 100,
      );
      await dao.upsertProgress(p1);

      final p2 = createProgress(
        groupId: 'g1',
        bookId: 'b1',
        pubKey: 'p1',
        milestonesReached: 1,
        updatedAt: 200,
        completed: true,
      );
      await dao.upsertProgress(p2);

      final result = await dao.getProgress(
        groupId: 'g1',
        bookId: 'b1',
        pubKey: 'p1',
      );
      expect(result, isNotNull);
      expect(result!.milestonesReached, 2); // Kept max
      expect(result.completed, true);
      expect(result.updatedAt, 200);
    },
  );

  test('upsertProgress ignores older updates', () async {
    final p1 = createProgress(
      groupId: 'g1',
      bookId: 'b1',
      pubKey: 'p1',
      updatedAt: 200,
      pageIndex: 5,
    );
    await dao.upsertProgress(p1);

    final p2 = createProgress(
      groupId: 'g1',
      bookId: 'b1',
      pubKey: 'p1',
      updatedAt: 100,
      pageIndex: 2,
    );
    await dao.upsertProgress(p2);

    final result = await dao.getProgress(
      groupId: 'g1',
      bookId: 'b1',
      pubKey: 'p1',
    );
    expect(result!.pageIndex, 5); // Kept the one with updatedAt = 200
  });

  test('watchAllProgressByGroupId returns all for group', () async {
    await dao.upsertProgress(
      createProgress(groupId: 'g1', bookId: 'b1', pubKey: 'p1'),
    );
    await dao.upsertProgress(
      createProgress(groupId: 'g1', bookId: 'b2', pubKey: 'p2'),
    );
    await dao.upsertProgress(
      createProgress(groupId: 'g2', bookId: 'b1', pubKey: 'p1'),
    );

    final stream = dao.watchAllProgressByGroupId('g1');
    final results = await stream.first;
    expect(results.length, 2);
  });

  test('watchMyProgress returns single stream for me', () async {
    await dao.upsertProgress(
      createProgress(groupId: 'g1', bookId: 'b1', pubKey: 'me'),
    );
    final stream = dao.watchMyProgress(
      groupId: 'g1',
      bookId: 'b1',
      myNpub: 'me',
    );
    final result = await stream.first;
    expect(result, isNotNull);
    expect(result!.pubKey, 'me');
  });

  test('countCompletedBooks returns correct count', () async {
    await dao.upsertProgress(
      createProgress(
        groupId: 'g1',
        bookId: 'b1',
        pubKey: 'me',
        completed: true,
      ),
    );
    await dao.upsertProgress(
      createProgress(
        groupId: 'g1',
        bookId: 'b2',
        pubKey: 'me',
        completed: false,
      ),
    );
    await dao.upsertProgress(
      createProgress(
        groupId: 'g2',
        bookId: 'b3',
        pubKey: 'me',
        completed: true,
      ),
    );

    final count = await dao.countCompletedBooks('me');
    expect(count, 2);
  });

  test('sumMilestonesReached returns correct sum', () async {
    await dao.upsertProgress(
      createProgress(
        groupId: 'g1',
        bookId: 'b1',
        pubKey: 'me',
        milestonesReached: 3,
      ),
    );
    await dao.upsertProgress(
      createProgress(
        groupId: 'g1',
        bookId: 'b2',
        pubKey: 'me',
        milestonesReached: 5,
      ),
    );
    await dao.upsertProgress(
      createProgress(
        groupId: 'g1',
        bookId: 'b3',
        pubKey: 'other',
        milestonesReached: 10,
      ),
    );

    final sum = await dao.sumMilestonesReached('me');
    expect(sum, 8);
  });
}
