import 'dart:async';
import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:uuid/uuid.dart';

import 'package:zapbook/core/data/database/dao/book_highlights_dao.dart';
import 'package:zapbook/core/data/infrastructure/highlight_private_sync_service.dart';
import 'package:zapbook/core/data/infrastructure/highlight_sync_service.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/features/book_reader/domain/entities/highlight.dart';
import 'package:zapbook/features/book_reader/domain/repositories/highlight_repository.dart';

@Injectable(as: HighlightRepository)
class HighlightRepositoryImpl implements HighlightRepository {
  HighlightRepositoryImpl(
    this._dao,
    this._privateSync,
    this._circleSync,
    this._identity,
  );

  final BookHighlightsDao _dao;
  final HighlightPrivateSyncService _privateSync;
  final HighlightSyncService _circleSync;
  final IdentityLocalDataSource _identity;
  final _log = logging.Logger('HighlightRepository');

  @override
  Future<Highlight?> saveHighlight({
    required String bookId,
    required int pageNumber,
    required List<HighlightSpan> spans,
    required String quoteSnapshot,
  }) async {
    final npub = await _identity.readNpub();
    if (npub == null || npub.isEmpty) return null;

    final now = DateTime.now();
    final highlight = Highlight(
      id: const Uuid().v4(),
      bookId: bookId,
      ownerNpub: npub,
      visibility: HighlightVisibility.private,
      pageNumber: pageNumber,
      spans: spans,
      quoteSnapshot: quoteSnapshot,
      createdAt: now,
      updatedAt: now,
    );

    await _dao.upsert(_toRecord(highlight));
    unawaited(_publishPrivate(highlight));
    return highlight;
  }

  @override
  Future<void> addOrUpdateNote({
    required String highlightId,
    required String note,
  }) async {
    final record = await _dao.getById(highlightId);
    if (record == null) return;

    final updated = _toDomain(
      record,
    ).copyWith(note: note, updatedAt: DateTime.now());

    await _dao.upsert(_toRecord(updated));
    unawaited(_publishPrivate(updated));
    if (updated.visibility == HighlightVisibility.circle) {
      unawaited(_circleSync.shareHighlight(updated));
    }
  }

  @override
  Future<void> shareToCircle({
    required String highlightId,
    required String groupId,
  }) async {
    final record = await _dao.getById(highlightId);
    if (record == null) return;

    final updated = _toDomain(record).copyWith(
      visibility: HighlightVisibility.circle,
      groupId: groupId,
      updatedAt: DateTime.now(),
    );

    await _dao.upsert(_toRecord(updated));
    unawaited(_publishPrivate(updated));
    unawaited(_circleSync.shareHighlight(updated));
  }

  @override
  Future<void> delete(String highlightId) async {
    final record = await _dao.getById(highlightId);
    if (record == null) return;

    final deleted = _toDomain(
      record,
    ).copyWith(deleted: true, updatedAt: DateTime.now());

    await _dao.softDelete(highlightId);
    unawaited(_publishPrivate(deleted));
    if (deleted.visibility == HighlightVisibility.circle) {
      unawaited(_circleSync.shareHighlight(deleted));
    }
  }

  @override
  Stream<List<Highlight>> watchPage({
    required String bookId,
    required int pageNumber,
  }) {
    return _dao
        .watchForPage(bookId: bookId, pageNumber: pageNumber)
        .map((records) => records.map(_toDomain).toList());
  }

  Future<void> _publishPrivate(Highlight highlight) async {
    try {
      await _privateSync.publish(highlight);
    } on Object catch (error, stack) {
      _log.warning('Private highlight sync failed', error, stack);
    }
  }

  Highlight _toDomain(HighlightRecord record) => Highlight(
    id: record.id,
    bookId: record.bookId,
    ownerNpub: record.ownerNpub,
    visibility: HighlightVisibility.values.byName(record.visibility),
    groupId: record.groupId,
    pageNumber: record.pageNumber,
    spans: record.spans.map(HighlightSpan.fromJson).toList(),
    quoteSnapshot: record.quoteSnapshot,
    note: record.note,
    createdAt: DateTime.fromMillisecondsSinceEpoch(record.createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(record.updatedAt),
    deleted: record.deleted,
  );

  HighlightRecord _toRecord(Highlight highlight) => HighlightRecord(
    id: highlight.id,
    bookId: highlight.bookId,
    ownerNpub: highlight.ownerNpub,
    visibility: highlight.visibility.name,
    groupId: highlight.groupId,
    pageNumber: highlight.pageNumber,
    spansJson: jsonEncode(highlight.spans.map((s) => s.toJson()).toList()),
    quoteSnapshot: highlight.quoteSnapshot,
    note: highlight.note,
    createdAt: highlight.createdAt.millisecondsSinceEpoch,
    updatedAt: highlight.updatedAt.millisecondsSinceEpoch,
    deleted: highlight.deleted,
  );
}
