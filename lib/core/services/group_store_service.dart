import 'package:marmot_dart/marmot_dart.dart';

abstract class GroupStoreService {
  Stream<List<MarmotGroup>> get watchGroups;

  List<MarmotGroup> get currentGroups;
  Stream<MarmotGroup> get onGroupUpdated;

  Future<void> deleteGroup(String groupId);

  void dispose();
}
