import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:zapbook/core/data/infrastructure/group_envelope_service.dart';
import 'package:zapbook/core/data/infrastructure/highlight_sync_service.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/features/book_reader/domain/entities/highlight.dart';

class MockMarmot extends Mock implements Marmot {}

class MockIdentityLocalDataSource extends Mock
    implements IdentityLocalDataSource {}

class MockGroupEnvelopeService extends Mock implements GroupEnvelopeService {}

void main() {
  late HighlightSyncService service;
  late MockMarmot mockMarmot;
  late MockIdentityLocalDataSource mockIdentity;
  late MockGroupEnvelopeService mockEnvelope;

  setUp(() {
    mockMarmot = MockMarmot();
    mockIdentity = MockIdentityLocalDataSource();
    mockEnvelope = MockGroupEnvelopeService();

    service = HighlightSyncService(mockMarmot, mockIdentity, mockEnvelope);
  });

  final sharedHighlight = Highlight(
    id: 'h1',
    bookId: 'book1',
    ownerNpub: 'npub1owner',
    visibility: HighlightVisibility.circle,
    groupId: 'group1',
    pageNumber: 3,
    spans: const [
      HighlightSpan(originalBlockIndex: 0, startOffset: 0, endOffset: 5),
    ],
    quoteSnapshot: 'quote',
    note: 'my note',
    createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(1000),
  );

  test('shareHighlight sends a structured message and publishes it', () async {
    when(() => mockIdentity.readNpub()).thenAnswer((_) async => 'npub1me');
    when(
      () => mockMarmot.sendStructured(any(), any(), any()),
    ).thenAnswer((_) async => 'event-json');
    when(() => mockEnvelope.publish(any())).thenAnswer((_) async {});

    await service.shareHighlight(sharedHighlight);

    final captured =
        verify(
              () =>
                  mockMarmot.sendStructured('npub1me', 'group1', captureAny()),
            ).captured.single
            as Map<String, dynamic>;

    expect(captured['type'], 'zapbook.highlight.shared');
    expect(captured['id'], 'h1');
    expect(captured['bookId'], 'book1');
    expect(captured['quoteSnapshot'], 'quote');
    expect(captured['note'], 'my note');
    expect(captured['deleted'], false);

    verify(() => mockEnvelope.publish('event-json')).called(1);
  });

  test('shareHighlight does nothing when there is no groupId', () async {
    final privateHighlight = sharedHighlight.copyWith(
      visibility: HighlightVisibility.private,
      groupId: '',
    );

    await service.shareHighlight(privateHighlight);

    verifyNever(() => mockMarmot.sendStructured(any(), any(), any()));
    verifyNever(() => mockEnvelope.publish(any()));
  });

  test('shareHighlight does nothing when npub is unavailable', () async {
    when(() => mockIdentity.readNpub()).thenAnswer((_) async => null);

    await service.shareHighlight(sharedHighlight);

    verifyNever(() => mockMarmot.sendStructured(any(), any(), any()));
    verifyNever(() => mockEnvelope.publish(any()));
  });
}
