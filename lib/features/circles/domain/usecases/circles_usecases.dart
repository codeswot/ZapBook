import 'package:injectable/injectable.dart';
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/core/domain/entities/pending_circle_upload.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/models/circle_member_progress.dart';
import 'package:zapbook/features/circles/domain/entities/share_skip.dart';
import 'package:zapbook/features/circles/domain/repositories/circles_repository.dart';

@injectable
class WatchCirclesUseCase {
  const WatchCirclesUseCase(this._repository);
  final CirclesRepository _repository;
  Stream<List<CircleBook>> call() => _repository.watchSharedCircles();
}

@injectable
class GetCircleMembersUseCase {
  const GetCircleMembersUseCase(this._repository);
  final CirclesRepository _repository;
  Future<List<Contact>> call(String circleId) =>
      _repository.getCircleMembers(circleId);
}

@injectable
class GetCircleBookUseCase {
  const GetCircleBookUseCase(this._repository);
  final CirclesRepository _repository;
  Future<CircleBook?> call(String circleId) =>
      _repository.getCircleBook(circleId);
}

@injectable
class RemoveCircleMemberUseCase {
  const RemoveCircleMemberUseCase(this._repository);
  final CirclesRepository _repository;
  Future<void> call(String circleId, String npub) =>
      _repository.removeCircleMember(circleId, npub);
}

@injectable
class ToggleContactUseCase {
  const ToggleContactUseCase(this._repository);
  final CirclesRepository _repository;
  Future<void> call(String npub, bool isFollow) =>
      _repository.toggleContact(npub, isFollow);
}

@injectable
class LeaveCircleBookUseCase {
  const LeaveCircleBookUseCase(this._repository);
  final CirclesRepository _repository;
  Future<void> call(CircleBook circleBook) =>
      _repository.leaveCircleBook(circleBook);
}

@injectable
class DeleteCircleBookUseCase {
  const DeleteCircleBookUseCase(this._repository);
  final CirclesRepository _repository;
  Future<void> call(CircleBook circleBook) =>
      _repository.deleteCircleBook(circleBook);
}

@injectable
class WatchProgressByBookUseCase {
  const WatchProgressByBookUseCase(this._repository);
  final CirclesRepository _repository;
  Stream<List<CircleMemberProgress>> call({
    required String groupId,
    required String bookId,
  }) => _repository.watchProgressByBook(groupId: groupId, bookId: bookId);
}

@injectable
class GetMyNpubUseCase {
  const GetMyNpubUseCase(this._repository);
  final CirclesRepository _repository;
  Future<String?> call() => _repository.getMyNpub();
}

@injectable
class SendCircleZapUseCase {
  const SendCircleZapUseCase(this._repository);
  final CirclesRepository _repository;
  Future<void> call({
    required Contact reader,
    required ZapGesture gesture,
    required String circleId,
  }) =>
      _repository.sendZap(reader: reader, gesture: gesture, circleId: circleId);
}

@injectable
class ShareCircleBookUseCase {
  const ShareCircleBookUseCase(this._repository);
  final CirclesRepository _repository;
  Future<List<ShareSkip>> call({
    required String circleBookId,
    required List<String> npubs,
    required String myNpub,
  }) => _repository.shareCircleBook(
    circleBookId: circleBookId,
    npubs: npubs,
    myNpub: myNpub,
  );
}

@injectable
class GetFriendsUseCase {
  const GetFriendsUseCase(this._repository);
  final CirclesRepository _repository;
  Future<List<Contact>> call() => _repository.getFriends();
}

@injectable
class GetExistingMemberNpubsUseCase {
  const GetExistingMemberNpubsUseCase(this._repository);
  final CirclesRepository _repository;
  Future<Set<String>> call(String circleBookId) =>
      _repository.getExistingMemberNpubs(circleBookId);
}

@injectable
class PrepareCircleCoverUseCase {
  const PrepareCircleCoverUseCase(this._repository);
  final CirclesRepository _repository;
  Future<dynamic> call(dynamic coverBytes) =>
      _repository.prepareCover(coverBytes: coverBytes);
}

@injectable
class UpdateCircleBookMetadataUseCase {
  const UpdateCircleBookMetadataUseCase(this._repository);
  final CirclesRepository _repository;
  Future<void> call({
    required String marmotGroupId,
    required String title,
    required String author,
    List<String>? genres,
  }) => _repository.updateCircleBookMetadata(
    marmotGroupId: marmotGroupId,
    title: title,
    author: author,
    genres: genres,
  );
}

@injectable
class SetUploadingCoverUseCase {
  const SetUploadingCoverUseCase(this._repository);
  final CirclesRepository _repository;
  void call(String marmotGroupId, String blurhash) =>
      _repository.setUploadingCover(marmotGroupId, blurhash);
}

@injectable
class ClearUploadingCoverUseCase {
  const ClearUploadingCoverUseCase(this._repository);
  final CirclesRepository _repository;
  void call(String marmotGroupId) =>
      _repository.clearUploadingCover(marmotGroupId);
}

@injectable
class UpdateCircleBookCoverOptimisticUseCase {
  const UpdateCircleBookCoverOptimisticUseCase(this._repository);
  final CirclesRepository _repository;
  void call({
    required String marmotGroupId,
    required String circleDirId,
    required dynamic coverBytes,
    required dynamic preparedImage,
    required String mimeType,
  }) => _repository.updateCircleBookCoverOptimistic(
    marmotGroupId: marmotGroupId,
    circleDirId: circleDirId,
    coverBytes: coverBytes,
    preparedImage: preparedImage,
    mimeType: mimeType,
  );
}

@injectable
class WatchPendingCircleUploadsUseCase {
  const WatchPendingCircleUploadsUseCase(this._repository);
  final CirclesRepository _repository;
  Stream<List<PendingCircleUpload>> call(String ownerNpub) =>
      _repository.watchPendingUploads(ownerNpub);
}

@injectable
class RetryPendingCircleUploadUseCase {
  const RetryPendingCircleUploadUseCase(this._repository);
  final CirclesRepository _repository;
  Future<void> call(PendingCircleUpload upload) =>
      _repository.retryPendingUpload(upload);
}

@injectable
class GetReseedRequestersUseCase {
  const GetReseedRequestersUseCase(this._repository);
  final CirclesRepository _repository;
  Future<List<String>> call({
    required String groupId,
    required String circleDirId,
  }) => _repository.getReseedRequesters(
    groupId: groupId,
    circleDirId: circleDirId,
  );
}

@injectable
class ReseedCircleBookUseCase {
  const ReseedCircleBookUseCase(this._repository);
  final CirclesRepository _repository;
  Future<void> call({
    required String groupId,
    required String circleDirId,
    required String myNpub,
  }) => _repository.reseedCircleBook(
    groupId: groupId,
    circleDirId: circleDirId,
    myNpub: myNpub,
  );
}

@injectable
class WatchUnreadAdminActionsUseCase {
  const WatchUnreadAdminActionsUseCase(this._repository);
  final CirclesRepository _repository;
  Stream<bool> call(String ownerNpub, String circleDirId) =>
      _repository.watchHasUnreadAdminActions(ownerNpub, circleDirId);
}

@injectable
class MarkAdminActionsAsReadUseCase {
  const MarkAdminActionsAsReadUseCase(this._repository);
  final CirclesRepository _repository;
  Future<void> call(String ownerNpub, String circleDirId) =>
      _repository.markAdminActionsAsRead(ownerNpub, circleDirId);
}

@injectable
class UploadCircleBookUseCase {
  const UploadCircleBookUseCase(this._repository);
  final CirclesRepository _repository;
  Future<void> call(String myNpub, String circleBookId) =>
      _repository.uploadCircleBook(myNpub, circleBookId);
}

@injectable
class WatchActiveUploadsUseCase {
  const WatchActiveUploadsUseCase(this._repository);
  final CirclesRepository _repository;
  Stream<Set<String>> call() => _repository.watchActiveUploads();
}
