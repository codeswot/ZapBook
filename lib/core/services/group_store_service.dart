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

  Future<String> setGroupImage({
    required String groupId,
    required Uint8List imageHash,
    required Uint8List imageKey,
    required Uint8List imageNonce,
    required Uint8List imageUploadKey,
  });

  Future<void> deleteGroup(String groupId);

  void dispose();
}
