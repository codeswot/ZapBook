import 'dart:typed_data';

import 'package:marmot_dart/marmot_dart.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/models/circle_member_progress.dart';
import 'package:zapbook/features/circles/domain/entities/share_skip.dart';

abstract class CirclesRepository {
  Stream<List<CircleBook>> watchSharedCircles();

  Future<List<Contact>> getCircleMembers(String circleId);
  Future<CircleBook?> getCircleBook(String circleId);

  Future<void> removeCircleMember(String circleId, String npub);
  Future<void> toggleContact(String npub, bool isFollow);

  Future<void> leaveCircleBook(CircleBook circleBook);
  Future<void> deleteCircleBook(CircleBook circleBook);

  Future<GroupImagePrepared> prepareCover({required Uint8List coverBytes});
  Future<void> updateCircleBookMetadata({
    required String marmotGroupId,
    required String title,
    required String author,
    String? genre,
  });
  void setUploadingCover(String marmotGroupId, String blurhash);
  void clearUploadingCover(String marmotGroupId);
  void updateCircleBookCoverOptimistic({
    required String marmotGroupId,
    required String circleDirId,
    required Uint8List coverBytes,
    required GroupImagePrepared preparedImage,
    required String mimeType,
  });

  Stream<List<CircleMemberProgress>> watchProgressByBook({
    required String groupId,
    required String bookId,
  });

  Future<String?> getMyNpub();

  Future<void> sendZap({
    required Contact reader,
    required ZapGesture gesture,
    required String circleId,
  });

  Future<List<ShareSkip>> shareCircleBook({
    required String circleBookId,
    required List<String> npubs,
    required String myNpub,
  });

  Future<List<Contact>> getFriends();
  Future<Set<String>> getExistingMemberNpubs(String circleBookId);
}
