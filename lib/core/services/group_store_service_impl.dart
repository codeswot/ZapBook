import 'dart:async';
import 'dart:typed_data';
import 'package:injectable/injectable.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:zapbook/core/config/zapbook_config.dart';
import 'package:zapbook/core/services/group_store_service.dart';
import 'package:zapbook/core/services/marmot_sync_service.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';

@LazySingleton(as: GroupStoreService)
class GroupStoreServiceImpl implements GroupStoreService {
  final MarmotSyncService _marmotSync;
  final Marmot _marmot;

  final IdentityLocalDataSource _identityLocal;

  final _groupsController = StreamController<List<MarmotGroup>>.broadcast();
  final _groupUpdatedController = StreamController<MarmotGroup>.broadcast();

  List<MarmotGroup> _currentGroups = [];
  final Map<String, MarmotGroup> _groupsMap = {};
  Future<void>? _initFuture;
  StreamSubscription? _sub;

  GroupStoreServiceImpl(this._marmotSync, this._marmot, this._identityLocal) {
    _initFuture = _init();
  }

  Future<void> _init() async {
    final groups = await _marmot.listGroups();
    _currentGroups = groups;
    _groupsController.add(_currentGroups);

    for (final g in groups) {
      _groupsMap[g.id] = g;
    }

    _sub = _marmotSync.onGroup.listen((updatedGroup) {
      _groupUpdatedController.add(updatedGroup);
      _groupsMap[updatedGroup.id] = updatedGroup;
      _currentGroups = _groupsMap.values.toList();
      _groupsController.add(_currentGroups);
    });
  }

  @override
  Stream<List<MarmotGroup>> get watchGroups async* {
    if (_initFuture != null) {
      await _initFuture;
      _initFuture = null;
    }
    yield _currentGroups;
    yield* _groupsController.stream;
  }

  @override
  List<MarmotGroup> get currentGroups => List.unmodifiable(_currentGroups);

  @override
  Stream<MarmotGroup> get onGroupUpdated => _groupUpdatedController.stream;

  @override
  Future<MarmotGroup> createGroup({
    required String name,
    required String description,
    required List<String> memberKeyPackageEventJsons,
  }) async {
    final creatorNpub = await _identityLocal.readNpub();
    if (creatorNpub == null || creatorNpub.isEmpty) {
      throw Exception('Cannot create group without logged in npub');
    }

    final params = CreateGroupParams(
      name: name,
      description: description,
      relayUrls: ZapbookConfig.broadcastRelays,
      memberKeyPackageEventJsons: memberKeyPackageEventJsons,
    );

    final result = await _marmot.createGroup(creatorNpub, params);
    final newGroup = result.group;

    _groupsMap[newGroup.id] = newGroup;
    _currentGroups = _groupsMap.values.toList();
    _groupsController.add(_currentGroups);

    return newGroup;
  }

  @override
  Future<String> updateGroupMetadata({
    required String groupId,
    String? name,
    String? description,
    List<String>? adminNpubs,
  }) async {
    final res = await _marmot.updateGroupMetadata(
      groupId,
      name: name,
      description: description,
      adminNpubs: adminNpubs,
      relayUrls: ZapbookConfig.broadcastRelays,
    );

    await _optimisticUpdate(groupId);
    return res;
  }

  @override
  Future<String> setGroupImage({
    required String groupId,
    required Uint8List imageHash,
    required Uint8List imageKey,
    required Uint8List imageNonce,
    required Uint8List imageUploadKey,
  }) async {
    final res = await _marmot.setGroupImage(
      groupId,
      imageHash: imageHash,
      imageKey: imageKey,
      imageNonce: imageNonce,
      imageUploadKey: imageUploadKey,
    );

    await _optimisticUpdate(groupId);
    return res;
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    await _marmot.deleteGroup(groupId);
    _groupsMap.remove(groupId);
    _currentGroups = _groupsMap.values.toList();
    _groupsController.add(_currentGroups);
  }

  Future<void> _optimisticUpdate(String groupId) async {
    final updated = await _marmot.getGroup(groupId);
    if (updated == null) return;

    _groupsMap[groupId] = updated;
    _currentGroups = _groupsMap.values.toList();
    _groupsController.add(_currentGroups);
    _groupUpdatedController.add(updated);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _groupsController.close();
    _groupUpdatedController.close();
  }
}
