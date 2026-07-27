import 'dart:async';
import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:zapbook/core/data/database/app_database.dart';

class HighlightRecord {
  final String id;
  final String bookId;
  final String ownerNpub;
  final String visibility;
  final String? groupId;
  final int pageNumber;
  final String spansJson;
  final String quoteSnapshot;
  final String? note;
  final int createdAt;
  final int updatedAt;
  final bool deleted;

  const HighlightRecord({
    required this.id,
    required this.bookId,
    required this.ownerNpub,
    required this.visibility,
    this.groupId,
    required this.pageNumber,
    required this.spansJson,
    required this.quoteSnapshot,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.deleted = false,
  });

  factory HighlightRecord.fromRow(Map<String, dynamic> row) => HighlightRecord(
    id: row['id'] as String,
    bookId: row['book_id'] as String,
    ownerNpub: row['owner_npub'] as String,
    visibility: row['visibility'] as String,
    groupId: row['group_id'] as String?,
    pageNumber: (row['page_number'] as num).toInt(),
    spansJson: row['spans_json'] as String,
    quoteSnapshot: row['quote_snapshot'] as String,
    note: row['note'] as String?,
    createdAt: (row['created_at'] as num).toInt(),
    updatedAt: (row['updated_at'] as num).toInt(),
    deleted: (row['deleted'] as num).toInt() == 1,
  );

  List<Map<String, dynamic>> get spans =>
      (jsonDecode(spansJson) as List<dynamic>).cast<Map<String, dynamic>>();
}

@lazySingleton
class BookHighlightsDao {
  BookHighlightsDao(this._db);

  final AppDatabase _db;
  final _changeController = StreamController<void>.broadcast();
  final _log = logging.Logger('BookHighlightsDao');

  Future<void> upsert(HighlightRecord record) async {
    try {
      final database = await _db.open();
      database.execute(
        '''
        INSERT OR REPLACE INTO book_highlights (
          id, book_id, owner_npub, visibility, group_id, page_number,
          spans_json, quote_snapshot, note, created_at, updated_at, deleted
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          record.id,
          record.bookId,
          record.ownerNpub,
          record.visibility,
          record.groupId,
          record.pageNumber,
          record.spansJson,
          record.quoteSnapshot,
          record.note,
          record.createdAt,
          record.updatedAt,
          record.deleted ? 1 : 0,
        ],
      );
      _changeController.add(null);
    } on Object catch (error, stack) {
      _log.warning('Failed to upsert highlight', error, stack);
    }
  }

  Future<void> softDelete(String id) async {
    try {
      final database = await _db.open();
      database.execute('UPDATE book_highlights SET deleted = 1 WHERE id = ?', [
        id,
      ]);
      _changeController.add(null);
    } on Object catch (error, stack) {
      _log.warning('Failed to soft-delete highlight', error, stack);
    }
  }

  Future<HighlightRecord?> getById(String id) async {
    try {
      final database = await _db.open();
      final rows = database.select(
        'SELECT * FROM book_highlights WHERE id = ?',
        [id],
      );
      if (rows.isEmpty) return null;
      return HighlightRecord.fromRow(rows.first);
    } on Object catch (error, stack) {
      _log.warning('Failed to load highlight by id', error, stack);
      return null;
    }
  }

  Future<List<HighlightRecord>> loadForPage({
    required String bookId,
    required int pageNumber,
  }) async {
    try {
      final database = await _db.open();
      final rows = database.select(
        '''
        SELECT * FROM book_highlights
        WHERE book_id = ? AND page_number = ? AND deleted = 0
        ''',
        [bookId, pageNumber],
      );
      return rows.map(HighlightRecord.fromRow).toList();
    } on Object catch (error, stack) {
      _log.warning('Failed to load highlights for page', error, stack);
      return [];
    }
  }

  Future<List<HighlightRecord>> loadForBook(String bookId) async {
    try {
      final database = await _db.open();
      final rows = database.select(
        'SELECT * FROM book_highlights WHERE book_id = ? AND deleted = 0',
        [bookId],
      );
      return rows.map(HighlightRecord.fromRow).toList();
    } on Object catch (error, stack) {
      _log.warning('Failed to load highlights for book', error, stack);
      return [];
    }
  }

  Stream<List<HighlightRecord>> watchForPage({
    required String bookId,
    required int pageNumber,
  }) {
    late StreamController<List<HighlightRecord>> controller;

    Future<void> emit() async {
      final records = await loadForPage(bookId: bookId, pageNumber: pageNumber);
      if (!controller.isClosed) {
        controller.add(records);
      }
    }

    controller = StreamController<List<HighlightRecord>>.broadcast(
      onListen: emit,
    );

    final sub = _changeController.stream.listen((_) => emit());

    controller.onCancel = () {
      sub.cancel();
      controller.close();
    };

    return controller.stream;
  }
}
