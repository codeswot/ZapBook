import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/services/circle_store_service.dart';
import 'package:zapbook/core/data/library_file_store.dart';
import 'package:zapbook/core/services/contact_service.dart';
import 'package:zapbook/core/services/group_store_service.dart';
import 'package:zapbook/core/services/key_package_service.dart';

class MockGroupStoreService extends Mock implements GroupStoreService {}

class MockLibraryFileStore extends Mock implements LibraryFileStore {}

class MockContactService extends Mock implements ContactService {}

class MockKeyPackageService extends Mock implements KeyPackageService {}

void main() {
  late MockGroupStoreService groupStore;
  late MockLibraryFileStore fileStore;
  late MockContactService contactStore;
  late MockKeyPackageService keyPackageService;
  late CircleStoreService service;

  setUp(() {
    groupStore = MockGroupStoreService();
    fileStore = MockLibraryFileStore();
    contactStore = MockContactService();
    keyPackageService = MockKeyPackageService();

    when(() => groupStore.watchGroups).thenAnswer((_) => Stream.value([]));

    service = CircleStoreService(
      groupStore,
      fileStore,
      contactStore,
      keyPackageService,
    );
  });

  test('watchCircleBooks yields empty initially', () {
    expect(service.watchCircleBooks, emitsInOrder([isEmpty]));
  });

  test('currentCircles returns empty initially', () {
    expect(service.currentCircles, isEmpty);
  });
}
