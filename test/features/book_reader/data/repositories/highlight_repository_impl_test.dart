import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/data/database/dao/book_highlights_dao.dart';
import 'package:zapbook/core/data/infrastructure/highlight_private_sync_service.dart';
import 'package:zapbook/core/data/infrastructure/highlight_sync_service.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/features/book_reader/data/repositories/highlight_repository_impl.dart';
import 'package:zapbook/features/book_reader/domain/entities/highlight.dart';

class MockBookHighlightsDao extends Mock implements BookHighlightsDao {}

class MockHighlightPrivateSyncService extends Mock
    implements HighlightPrivateSyncService {}

class MockHighlightSyncService extends Mock implements HighlightSyncService {}

class MockIdentityLocalDataSource extends Mock
    implements IdentityLocalDataSource {}

class FakeHighlightRecord extends Fake implements HighlightRecord {}

void main() {
  late HighlightRepositoryImpl repository;
  late MockBookHighlightsDao mockDao;
  late MockHighlightPrivateSyncService mockPrivateSync;
  late MockHighlightSyncService mockCircleSync;
  late MockIdentityLocalDataSource mockIdentity;

  setUpAll(() {
    registerFallbackValue(FakeHighlightRecord());
    registerFallbackValue(
      Highlight(
        id: '',
        bookId: '',
        ownerNpub: '',
        visibility: HighlightVisibility.private,
        pageNumber: 0,
        spans: const [],
        quoteSnapshot: '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );
  });

  setUp(() {
    mockDao = MockBookHighlightsDao();
    mockPrivateSync = MockHighlightPrivateSyncService();
    mockCircleSync = MockHighlightSyncService();
    mockIdentity = MockIdentityLocalDataSource();

    when(() => mockDao.upsert(any())).thenAnswer((_) async {});
    when(() => mockPrivateSync.publish(any())).thenAnswer((_) async {});
    when(() => mockCircleSync.shareHighlight(any())).thenAnswer((_) async {});

    repository = HighlightRepositoryImpl(
      mockDao,
      mockPrivateSync,
      mockCircleSync,
      mockIdentity,
    );
  });

  HighlightRecord existingRecord({
    String visibility = 'private',
    String? groupId,
  }) => HighlightRecord(
    id: 'h1',
    bookId: 'book1',
    ownerNpub: 'npub1owner',
    visibility: visibility,
    groupId: groupId,
    pageNumber: 3,
    spansJson: '[{"originalBlockIndex":0,"startOffset":0,"endOffset":5}]',
    quoteSnapshot: 'quote',
    createdAt: 1000,
    updatedAt: 1000,
  );

  test('saveHighlight persists locally and publishes privately', () async {
    when(() => mockIdentity.readNpub()).thenAnswer((_) async => 'npub1owner');

    final result = await repository.saveHighlight(
      bookId: 'book1',
      pageNumber: 3,
      spans: const [
        HighlightSpan(originalBlockIndex: 0, startOffset: 0, endOffset: 5),
      ],
      quoteSnapshot: 'quote',
    );

    expect(result, isNotNull);
    expect(result!.bookId, 'book1');
    expect(result.ownerNpub, 'npub1owner');
    expect(result.visibility, HighlightVisibility.private);

    verify(() => mockDao.upsert(any())).called(1);
    await untilCalled(() => mockPrivateSync.publish(any()));
    verify(() => mockPrivateSync.publish(any())).called(1);
  });

  test('saveHighlight returns null when npub is unavailable', () async {
    when(() => mockIdentity.readNpub()).thenAnswer((_) async => null);

    final result = await repository.saveHighlight(
      bookId: 'book1',
      pageNumber: 3,
      spans: const [],
      quoteSnapshot: 'quote',
    );

    expect(result, isNull);
    verifyNever(() => mockDao.upsert(any()));
  });

  test('addOrUpdateNote sets the note and re-persists', () async {
    when(() => mockDao.getById('h1')).thenAnswer((_) async => existingRecord());

    await repository.addOrUpdateNote(highlightId: 'h1', note: 'a thought');

    final captured =
        verify(() => mockDao.upsert(captureAny())).captured.single
            as HighlightRecord;
    expect(captured.note, 'a thought');
  });

  test('addOrUpdateNote re-shares to circle when already shared', () async {
    when(() => mockDao.getById('h1')).thenAnswer(
      (_) async => existingRecord(visibility: 'circle', groupId: 'group1'),
    );

    await repository.addOrUpdateNote(highlightId: 'h1', note: 'a thought');

    await untilCalled(() => mockCircleSync.shareHighlight(any()));
    verify(() => mockCircleSync.shareHighlight(any())).called(1);
  });

  test('shareToCircle flips visibility and shares via circle sync', () async {
    when(() => mockDao.getById('h1')).thenAnswer((_) async => existingRecord());

    await repository.shareToCircle(highlightId: 'h1', groupId: 'group1');

    final captured =
        verify(() => mockDao.upsert(captureAny())).captured.single
            as HighlightRecord;
    expect(captured.visibility, 'circle');
    expect(captured.groupId, 'group1');

    verify(() => mockCircleSync.shareHighlight(any())).called(1);
  });

  test('delete soft-deletes locally and republishes tombstone', () async {
    when(() => mockDao.getById('h1')).thenAnswer((_) async => existingRecord());
    when(() => mockDao.softDelete('h1')).thenAnswer((_) async {});

    await repository.delete('h1');

    verify(() => mockDao.softDelete('h1')).called(1);
    await untilCalled(() => mockPrivateSync.publish(any()));
    final captured =
        verify(() => mockPrivateSync.publish(captureAny())).captured.single
            as Highlight;
    expect(captured.deleted, isTrue);
  });

  test('watchPage maps DAO records to domain highlights', () async {
    when(
      () => mockDao.watchForPage(bookId: 'book1', pageNumber: 3),
    ).thenAnswer((_) => Stream.value([existingRecord()]));

    final result = await repository
        .watchPage(bookId: 'book1', pageNumber: 3)
        .first;

    expect(result.length, 1);
    expect(result.first.id, 'h1');
    expect(result.first.quoteSnapshot, 'quote');
  });
}
