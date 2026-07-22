import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:zapbook/core/data/infrastructure/circle_share_service.dart';
import 'package:zapbook/core/models/book_manifest_payload.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:zapbook/core/data/infrastructure/blossom_service.dart';
import 'package:zapbook/core/data/library_file_store.dart';
import 'package:zapbook/core/data/infrastructure/group_envelope_service.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/data/database/dao/book_key_dao.dart';
import 'dart:io';

class MockMarmot extends Mock implements Marmot {}

class MockBlossomService extends Mock implements BlossomService {}

class MockLibraryFileStore extends Mock implements LibraryFileStore {}

class MockGroupEnvelopeService extends Mock implements GroupEnvelopeService {}

class MockIdentityLocalDataSource extends Mock
    implements IdentityLocalDataSource {}

class MockBookKeyDao extends Mock implements BookKeyDao {}

class MockDirectory extends Mock implements Directory {}

void main() {
  late MockMarmot marmot;
  late MockBlossomService blossom;
  late MockLibraryFileStore fileStore;
  late MockGroupEnvelopeService envelope;
  late MockIdentityLocalDataSource identity;
  late MockBookKeyDao bookKeyDao;
  late CircleShareService service;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    marmot = MockMarmot();
    blossom = MockBlossomService();
    fileStore = MockLibraryFileStore();
    envelope = MockGroupEnvelopeService();
    identity = MockIdentityLocalDataSource();
    bookKeyDao = MockBookKeyDao();
    when(() => identity.readNpub()).thenAnswer((_) async => null);
    service = CircleShareService(
      marmot,
      blossom,
      fileStore,
      envelope,
      identity,
      bookKeyDao,
    );
  });

  group('CircleShareService', () {
    test('uploadBookContent early exit if ZBF not found', () async {
      final mockDir = MockDirectory();
      when(() => mockDir.exists()).thenAnswer((_) async => false);
      when(() => fileStore.zbfFile(any())).thenAnswer((_) async => mockDir);

      await service.uploadBookContent('npub', 'groupId', 'circleDirId');
      verify(() => fileStore.zbfFile('circleDirId')).called(1);
    });

    test('fetchAndDownloadBook fails if no messages', () async {
      when(() => marmot.getMessages(any())).thenAnswer((_) async => []);

      final result = await service.fetchAndDownloadBook(
        'groupId',
        'circleDirId',
      );
      expect(result, isFalse);
    });

    test('downloadBookContent handles error gracefully', () async {
      final result = await service.downloadBookContent(
        'circleDirId',
        'groupId',
        BookManifestPayload(
          circleDirId: '1',
          keyHex: '',
          ivHex: '',
          segments: [],
        ),
      );
      expect(result, isFalse);
    });
  });
}
