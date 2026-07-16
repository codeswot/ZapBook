import 'dart:typed_data';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:injectable/injectable.dart';
import 'package:zapbook/core/data/infrastructure/circle_store_service.dart';
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/models/circle_member_progress.dart';
import 'package:zapbook/features/circles/domain/entities/share_skip.dart';
import 'package:zapbook/features/circles/data/datasources/circles_data_source.dart';
import 'package:zapbook/features/circles/domain/repositories/circles_repository.dart';

@LazySingleton(as: CirclesRepository)
class CirclesRepositoryImpl implements CirclesRepository {
  const CirclesRepositoryImpl(this._dataSource, this._circleStoreService);

  final CirclesDataSource _dataSource;
  final CircleStoreService _circleStoreService;

  @override
  Stream<List<CircleBook>> watchSharedCircles() =>
      _dataSource.watchSharedCircles();

  @override
  Future<List<Contact>> getCircleMembers(String circleId) =>
      _dataSource.getCircleMembers(circleId);

  @override
  Future<CircleBook?> getCircleBook(String circleId) =>
      _dataSource.getCircleBook(circleId);

  @override
  Future<void> removeCircleMember(String circleId, String npub) =>
      _dataSource.removeCircleMember(circleId, npub);

  @override
  Future<void> toggleContact(String npub, bool isFollow) =>
      _dataSource.toggleContact(npub, isFollow);

  @override
  Future<void> leaveCircleBook(CircleBook circleBook) async {
    await _circleStoreService.leaveCircleBook(circleBook);
  }

  @override
  Future<void> deleteCircleBook(CircleBook circleBook) async {
    await _circleStoreService.deleteCircleBook(circleBook);
  }

  @override
  Future<GroupImagePrepared> prepareCover({
    required Uint8List coverBytes,
  }) async {
    return _circleStoreService.prepareCover(coverBytes: coverBytes);
  }

  @override
  Future<void> updateCircleBookMetadata({
    required String marmotGroupId,
    required String title,
    required String author,
    List<String>? genres,
  }) async {
    await _circleStoreService.updateCircleBookMetadata(
      marmotGroupId: marmotGroupId,
      title: title,
      author: author,
      genres: genres,
    );
  }

  @override
  void setUploadingCover(String marmotGroupId, String blurhash) {
    _circleStoreService.setUploadingCover(marmotGroupId, blurhash);
  }

  @override
  void clearUploadingCover(String marmotGroupId) {
    _circleStoreService.clearUploadingCover(marmotGroupId);
  }

  @override
  void updateCircleBookCoverOptimistic({
    required String marmotGroupId,
    required String circleDirId,
    required Uint8List coverBytes,
    required GroupImagePrepared preparedImage,
    required String mimeType,
  }) {
    _circleStoreService.updateCircleBookCoverOptimistic(
      marmotGroupId: marmotGroupId,
      circleDirId: circleDirId,
      coverBytes: coverBytes,
      preparedImage: preparedImage,
      mimeType: mimeType,
    );
  }

  @override
  Stream<List<CircleMemberProgress>> watchProgressByBook({
    required String groupId,
    required String bookId,
  }) => _dataSource.watchProgressByBook(groupId: groupId, bookId: bookId);

  @override
  Future<String?> getMyNpub() => _dataSource.getMyNpub();

  @override
  Future<void> sendZap({
    required Contact reader,
    required ZapGesture gesture,
    required String circleId,
  }) =>
      _dataSource.sendZap(reader: reader, gesture: gesture, circleId: circleId);

  @override
  Future<List<ShareSkip>> shareCircleBook({
    required String circleBookId,
    required List<String> npubs,
    required String myNpub,
  }) => _dataSource.shareCircleBook(
    circleBookId: circleBookId,
    npubs: npubs,
    myNpub: myNpub,
  );

  @override
  Future<List<Contact>> getFriends() => _dataSource.getFriends();

  @override
  Future<Set<String>> getExistingMemberNpubs(String circleBookId) =>
      _dataSource.getExistingMemberNpubs(circleBookId);
}
