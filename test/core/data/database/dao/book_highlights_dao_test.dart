import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/core/data/database/app_database.dart';
import 'package:zapbook/core/data/database/dao/book_highlights_dao.dart';

void main() {
  late Directory tempDir;
  late AppDatabase db;
  late BookHighlightsDao dao;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('book_highlights_dao_test');
    db = AppDatabase.forPath('${tempDir.path}/app.db');
    dao = BookHighlightsDao(db);
  });

  tearDown(() {
    db.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  HighlightRecord createRecord({
    String id = 'h1',
    String bookId = 'book1',
    int pageNumber = 3,
    bool deleted = false,
  }) {
    return HighlightRecord(
      id: id,
      bookId: bookId,
      ownerNpub: 'npub1owner',
      visibility: 'private',
      pageNumber: pageNumber,
      spansJson: '[{"originalBlockIndex":0,"startOffset":0,"endOffset":5}]',
      quoteSnapshot: 'quote',
      createdAt: 1000,
      updatedAt: 1000,
      deleted: deleted,
    );
  }

  test('upsert and loadForPage round-trips a record', () async {
    await dao.upsert(createRecord());

    final loaded = await dao.loadForPage(bookId: 'book1', pageNumber: 3);
    expect(loaded.length, 1);
    expect(loaded.first.id, 'h1');
    expect(loaded.first.quoteSnapshot, 'quote');
    expect(loaded.first.spans.single['startOffset'], 0);
  });

  test('loadForPage excludes soft-deleted records', () async {
    await dao.upsert(createRecord());
    await dao.softDelete('h1');

    final loaded = await dao.loadForPage(bookId: 'book1', pageNumber: 3);
    expect(loaded, isEmpty);
  });

  test('loadForBook returns records across pages', () async {
    await dao.upsert(createRecord(id: 'h1', pageNumber: 1));
    await dao.upsert(createRecord(id: 'h2', pageNumber: 2));

    final loaded = await dao.loadForBook('book1');
    expect(loaded.length, 2);
  });

  test('getById returns the matching record or null', () async {
    await dao.upsert(createRecord());

    expect((await dao.getById('h1'))?.id, 'h1');
    expect(await dao.getById('missing'), isNull);
  });

  test('watchForPage emits on upsert', () async {
    final stream = dao.watchForPage(bookId: 'book1', pageNumber: 3);

    final nextUpdate = stream.skip(1).first;
    await dao.upsert(createRecord());

    final records = await nextUpdate;
    expect(records.length, 1);
    expect(records.first.id, 'h1');
  });

  test('upsert with same id replaces the previous record', () async {
    await dao.upsert(createRecord());
    final replaced = createRecord();
    await dao.upsert(
      HighlightRecord(
        id: replaced.id,
        bookId: replaced.bookId,
        ownerNpub: replaced.ownerNpub,
        visibility: replaced.visibility,
        pageNumber: replaced.pageNumber,
        spansJson: replaced.spansJson,
        quoteSnapshot: 'updated quote',
        createdAt: replaced.createdAt,
        updatedAt: 2000,
      ),
    );

    final loaded = await dao.loadForPage(bookId: 'book1', pageNumber: 3);
    expect(loaded.length, 1);
    expect(loaded.first.quoteSnapshot, 'updated quote');
  });
}
