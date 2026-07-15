import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/data/infrastructure/circle_store_service.dart';
import 'package:zapbook/core/data/library_file_store.dart';
import 'package:zapbook/core/data/infrastructure/contact_service.dart';
import 'package:zapbook/core/data/infrastructure/group_store_service.dart';
import 'package:zapbook/core/data/infrastructure/key_package_service.dart';

import 'package:marmot_dart/marmot_dart.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/zbf/enums/book_source_format.dart';
import 'package:zapbook/core/domain/contact.dart';

class MockGroupStoreService extends Mock implements GroupStoreService {}

class MockLibraryFileStore extends Mock implements LibraryFileStore {}

class MockContactService extends Mock implements ContactService {}

class MockKeyPackageService extends Mock implements KeyPackageService {}

class MockMarmotGroup extends Mock implements MarmotGroup {}

class MockGroupImagePrepared extends Mock implements GroupImagePrepared {}

class MockContact extends Mock implements Contact {}

class MockMarmotMember extends Mock implements MarmotMember {}

void main() {
  late MockGroupStoreService groupStore;
  late MockLibraryFileStore fileStore;
  late MockContactService contactStore;
  late MockKeyPackageService keyPackageService;
  late CircleStoreService service;
  late StreamController<List<MarmotGroup>> groupStreamCtrl;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(MockGroupImagePrepared());
  });

  setUp(() {
    groupStore = MockGroupStoreService();
    fileStore = MockLibraryFileStore();
    contactStore = MockContactService();
    keyPackageService = MockKeyPackageService();
    groupStreamCtrl = StreamController<List<MarmotGroup>>.broadcast();

    when(
      () => groupStore.watchGroups,
    ).thenAnswer((_) => groupStreamCtrl.stream);

    service = CircleStoreService(
      groupStore,
      fileStore,
      contactStore,
      keyPackageService,
    );
  });

  tearDown(() {
    groupStreamCtrl.close();
    service.dispose();
  });

  test('watchCircleBooks yields empty initially', () {
    expect(service.watchCircleBooks, emitsInOrder([isEmpty]));
  });

  test('currentCircles returns empty initially', () {
    expect(service.currentCircles, isEmpty);
  });

  test('setUploadingCover and clearUploadingCover work', () {
    service.setUploadingCover('g1', 'blurhash1');
    expect(service.currentUploadingCovers['g1'], 'blurhash1');
    service.clearUploadingCover('g1');
    expect(service.currentUploadingCovers.containsKey('g1'), isFalse);
  });

  test('createCircleBook calls group store', () async {
    final mockGroup = MockMarmotGroup();
    when(() => mockGroup.id).thenReturn('g1');
    when(
      () => groupStore.createGroup(
        name: any(named: 'name'),
        description: any(named: 'description'),
        memberKeyPackageEventJsons: any(named: 'memberKeyPackageEventJsons'),
      ),
    ).thenAnswer((_) async => mockGroup);

    final id = await service.createCircleBook(
      circleDirId: 'dir1',
      humanTitle: 'title',
      metadata: {'author': 'test'},
    );
    expect(id, 'g1');
  });

  test('deleteCircleBook calls store services', () async {
    when(() => groupStore.deleteGroup(any())).thenAnswer((_) async {});
    when(() => fileStore.deleteBook(any())).thenAnswer((_) async {});
    when(() => keyPackageService.forceRotate()).thenAnswer((_) async => true);

    final mockBook = CircleBook(
      id: 'g1',
      nostrGroudId: 'n1',
      circleDirId: 'dir1',
      title: 'title',
      author: 'author',
      memberCount: 1,
      addedAt: DateTime.now(),
      createdAt: DateTime.now(),
      sourceFormat: BookSourceFormat.epub,
      pageCount: 10,
      chapterCount: 1,
      zbfPath: 'path',
      needsAiProcessing: false,
      zbfVersion: '1',
      adminNpubs: [],
    );

    await service.deleteCircleBook(mockBook);
    verify(() => groupStore.deleteGroup('g1')).called(1);
    verify(() => fileStore.deleteBook('dir1')).called(1);
  });

  test('leaveCircleBook calls groupStore', () async {
    when(() => groupStore.leaveGroup(any())).thenAnswer((_) async {});
    final mockBook = CircleBook(
      id: 'g1',
      nostrGroudId: 'n1',
      circleDirId: 'dir1',
      title: 'title',
      author: 'author',
      memberCount: 1,
      addedAt: DateTime.now(),
      createdAt: DateTime.now(),
      sourceFormat: BookSourceFormat.epub,
      pageCount: 10,
      chapterCount: 1,
      zbfPath: 'path',
      needsAiProcessing: false,
      zbfVersion: '1',
      adminNpubs: [],
    );
    await service.leaveCircleBook(mockBook);
    verify(() => groupStore.leaveGroup('g1')).called(1);
  });

  test('init processes groups and maps to circle books', () async {
    final mockGroup = MockMarmotGroup();
    when(() => mockGroup.id).thenReturn('g1');
    when(() => mockGroup.name).thenReturn('zapbook-circle-dir1:Title');
    when(() => mockGroup.description).thenReturn('{"author": "test"}');
    when(() => mockGroup.memberCount).thenReturn(2);
    when(() => mockGroup.adminNpubs).thenReturn(['admin1']);
    when(() => mockGroup.imageHash).thenReturn(null);
    when(() => mockGroup.imageKey).thenReturn(null);
    when(() => mockGroup.imageNonce).thenReturn(null);
    when(() => mockGroup.nostrGroupId).thenReturn('n1');

    final zbfMock = Directory('test.zbf');
    when(() => fileStore.zbfFile(any())).thenAnswer((_) async => zbfMock);
    when(
      () => fileStore.coverPathIfExists('dir1'),
    ).thenAnswer((_) async => null);

    groupStreamCtrl.add([mockGroup]);

    await expectLater(
      service.watchCircleBooks,
      emitsThrough(
        predicate<List<CircleBook>>(
          (books) => books.isNotEmpty && books.first.id == 'g1',
        ),
      ),
    );
  });

  test('updateCircleBookMetadata calls updateGroupMetadata', () async {
    final mockGroup = MockMarmotGroup();
    when(() => mockGroup.id).thenReturn('g1');
    when(() => mockGroup.name).thenReturn('zapbook-circle-dir1:Title');
    when(() => mockGroup.description).thenReturn('{"author": "test"}');
    when(() => groupStore.currentGroups).thenReturn([mockGroup]);
    when(
      () => groupStore.updateGroupMetadata(
        groupId: any(named: 'groupId'),
        name: any(named: 'name'),
        description: any(named: 'description'),
      ),
    ).thenAnswer((_) async => '');

    await service.updateCircleBookMetadata(
      marmotGroupId: 'g1',
      author: 'new_author',
      title: 'New Title',
    );

    verify(
      () => groupStore.updateGroupMetadata(
        groupId: 'g1',
        name: 'zapbook-circle-dir1:New Title',
        description: '{"author":"new_author"}',
      ),
    ).called(1);
  });

  test('prepareCover and updateCircleBookCoverOptimistic work', () async {
    final prepared = MockGroupImagePrepared();
    when(() => prepared.imageHash).thenReturn(Uint8List.fromList([1, 2, 3]));
    when(
      () => groupStore.prepareImage(any()),
    ).thenAnswer((_) async => prepared);
    when(
      () => groupStore.uploadImage(any(), any()),
    ).thenAnswer((_) async => 'url');
    when(
      () => groupStore.setGroupImage(
        groupId: any(named: 'groupId'),
        preparedImage: any(named: 'preparedImage'),
      ),
    ).thenAnswer((_) async => '');
    when(
      () => fileStore.writeCover(
        any(),
        any(),
        imageHashHex: any(named: 'imageHashHex'),
      ),
    ).thenAnswer((_) async => '');
    when(
      () => fileStore.coverPathIfExists(
        any(),
        imageHashHex: any(named: 'imageHashHex'),
      ),
    ).thenAnswer((_) async => null);

    final p = await service.prepareCover(coverBytes: Uint8List(0));
    expect(p, prepared);

    service.updateCircleBookCoverOptimistic(
      marmotGroupId: 'g1',
      circleDirId: 'dir1',
      coverBytes: Uint8List(0),
      preparedImage: prepared,
      mimeType: 'image/jpeg',
    );

    await Future.delayed(const Duration(milliseconds: 100));

    verify(() => groupStore.uploadImage(prepared, 'image/jpeg')).called(1);
    verify(
      () => fileStore.writeCover(
        'dir1',
        any(),
        imageHashHex: any(named: 'imageHashHex'),
      ),
    ).called(1);
  });

  test(
    'getCircleMembers, addCircleMember, removeCircleMember map to groupStore',
    () async {
      final member = MockMarmotMember();
      when(() => member.npub).thenReturn('npub1');
      when(() => groupStore.getMembers('g1')).thenAnswer((_) async => [member]);
      final contact = MockContact();
      when(
        () => contactStore.resolve('npub1'),
      ).thenAnswer((_) async => contact);

      final members = await service.getCircleMembers('g1');
      expect(members, [contact]);

      when(
        () => groupStore.addMember('g1', 'json'),
      ).thenAnswer((_) async => null);
      await service.addCircleMember('g1', 'json');
      verify(() => groupStore.addMember('g1', 'json')).called(1);

      when(
        () => groupStore.removeMember('g1', 'npub1'),
      ).thenAnswer((_) async {});
      await service.removeCircleMember('g1', 'npub1');
      verify(() => groupStore.removeMember('g1', 'npub1')).called(1);
    },
  );
}
