import 'dart:typed_data';

import 'package:marmot_dart/marmot_dart.dart';

abstract class GroupStoreService {
  Stream<List<MarmotGroup>> get watchGroups;

  List<MarmotGroup> get currentGroups;
  Stream<MarmotGroup> get onGroupUpdated;
  Future<MarmotGroup> createGroup({
    required String name,
    required String description,
    required List<String> memberKeyPackageEventJsons,
  });

  Future<String> updateGroupMetadata({
    required String groupId,
    String? name,
    String? description,
    List<String>? adminNpubs,
  });

  Future<GroupImagePrepared> prepareImage(Uint8List imageBytes);
  Future<void> uploadImage(GroupImagePrepared prep, String mimeType);

  Future<Uint8List?> downloadImage(
    Uint8List imageHash,
    Uint8List? imageKey,
    Uint8List? imageNonce,
  );

  Future<String> setGroupImage({
    required String groupId,
    required GroupImagePrepared preparedImage,
  });

  Future<void> deleteGroup(String groupId);

  void dispose();
}
