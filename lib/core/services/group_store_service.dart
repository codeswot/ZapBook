import 'dart:async';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:mime/mime.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:rxdart/rxdart.dart';
import 'package:zapbook/core/config/zapbook_config.dart';
import 'package:zapbook/core/services/marmot_sync_service.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/blossom_service.dart';
import 'package:zapbook/core/services/group_envelope_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

@LazySingleton()
class GroupStoreService {
  final MarmotSyncService _marmotSync;
  final Marmot _marmot;

  final IdentityLocalDataSource _identityLocal;

  final _groupsSubject = BehaviorSubject<List<MarmotGroup>>.seeded(const []);
  final _groupUpdatedSubject = PublishSubject<MarmotGroup>();
  final _log = logging.Logger('GroupStoreService');
  final Map<String, MarmotGroup> _groupsMap = {};
  Future<void>? _initFuture;
  StreamSubscription? _sub;
  StreamSubscription? _syncSub;

  GroupStoreService(
    this._marmotSync,
    this._marmot,
    this._identityLocal,
    this._blossom,
    this._envelope,
    this._prefs,
  ) {
    _initFuture = _init();
  }

  final BlossomService _blossom;
  final GroupEnvelopeService _envelope;
  final SharedPreferences _prefs;

  List<String> get _deletedGroupIds =>
      _prefs.getStringList('deleted_groups') ?? [];

  Future<void> _init() async {
    await _refreshGroups();

    _sub = _marmotSync.onGroup.listen((updatedGroup) {
      if (_deletedGroupIds.contains(updatedGroup.id)) return;
      _groupsMap[updatedGroup.id] = updatedGroup;
      _groupsSubject.add(_groupsMap.values.toList());
      _groupUpdatedSubject.add(updatedGroup);
    });

    _syncSub = _marmotSync.onSync.listen((_) => _refreshGroups());
  }

  Future<void> _refreshGroups() async {
    final groups = await _marmot.listGroups();
    final deletedIds = _deletedGroupIds.toSet();

    bool changed = false;
    final newMap = <String, MarmotGroup>{};

    for (final g in groups) {
      if (deletedIds.contains(g.id)) continue;
      newMap[g.id] = g;

      if (_groupsMap[g.id] != g) {
        changed = true;
      }
    }

    if (_groupsMap.length != newMap.length) {
      changed = true;
    }

    if (changed) {
      _groupsMap.clear();
      _groupsMap.addAll(newMap);
      _groupsSubject.add(_groupsMap.values.toList());
    }
  }

  Stream<List<MarmotGroup>> get watchGroups async* {
    if (_initFuture != null) {
      await _initFuture;
    }
    yield* _groupsSubject.stream;
  }

  List<MarmotGroup> get currentGroups => _groupsSubject.value;

  Stream<MarmotGroup> get onGroupUpdated => _groupUpdatedSubject.stream;

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
    _groupsSubject.add(_groupsMap.values.toList());
    return newGroup;
  }

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

  Future<GroupImagePrepared> prepareImage(Uint8List imageBytes) async {
    final mimeType =
        lookupMimeType('', headerBytes: imageBytes) ?? 'image/jpeg';
    return await Marmot.prepareGroupImage(imageBytes, mimeType);
  }

  Future<void> uploadImage(GroupImagePrepared prep, String mimeType) async {
    await _blossom.upload(prep.encryptedData, mimeType: mimeType);
  }

  Future<Uint8List?> downloadImage(
    Uint8List imageHash,
    Uint8List? imageKey,
    Uint8List? imageNonce,
  ) async {
    try {
      final hashHex = hex.encode(imageHash);
      final url = '${BlossomService.servers.first}/$hashHex';
      final encryptedData = await _blossom.download(url);

      if (imageKey != null && imageNonce != null) {
        return await Marmot.decryptGroupImage(
          encryptedData: encryptedData,
          imageHash: imageHash,
          imageKey: imageKey,
          imageNonce: imageNonce,
        );
      }
      return encryptedData;
    } catch (e, st) {
      _log.warning('Failed to download image', e, st);
      return null;
    }
  }

  Future<String> setGroupImage({
    required String groupId,
    required GroupImagePrepared preparedImage,
  }) async {
    final res = await _marmot.setGroupImage(
      groupId,
      imageHash: preparedImage.imageHash,
      imageKey: preparedImage.imageKey,
      imageNonce: preparedImage.imageNonce,
      imageUploadKey: preparedImage.imageUploadKey,
    );
    _envelope.publish(res);

    await _optimisticUpdate(groupId);
    return res;
  }

  Future<void> deleteGroup(String groupId) async {
    try {
      final deletedIds = _deletedGroupIds;
      if (!deletedIds.contains(groupId)) {
        await _prefs.setStringList('deleted_groups', [...deletedIds, groupId]);
      }
      await _marmot.deleteGroup(groupId);
    } catch (e, st) {
      _log.warning(
        'Marmot deleteGroup failed, continuing local deletion',
        e,
        st,
      );
    }
    _groupsMap.remove(groupId);
    _groupsSubject.add(_groupsMap.values.toList());
  }

  Future<void> leaveGroup(String groupId) async {
    try {
      final res = await _marmot.leaveGroup(groupId);
      _envelope.publish(res.evolutionEventJson);
    } catch (e, st) {
      _log.warning('Marmot leaveGroup failed', e, st);
    }
  }

  Future<void> _optimisticUpdate(String groupId) async {
    final updated = await _marmot.getGroup(groupId);
    if (updated == null) return;

    _groupsMap[groupId] = updated;
    _groupsSubject.add(_groupsMap.values.toList());
    _groupUpdatedSubject.add(updated);
  }

  Future<List<MarmotMember>> getMembers(String groupId) async {
    return await _marmot.getMembers(groupId);
  }

  Future<void> removeMember(String groupId, String memberNpub) async {
    try {
      final res = await _marmot.removeMember(groupId, memberNpub);
      _envelope.publish(res.evolutionEventJson);
    } catch (e, st) {
      _log.warning('Marmot removeMember failed', e, st);
    }
  }

  Future<void> refreshGroup(String groupId) => _optimisticUpdate(groupId);

  @disposeMethod
  void dispose() {
    _sub?.cancel();
    _syncSub?.cancel();
    _groupsSubject.close();
    _groupUpdatedSubject.close();
  }
}
