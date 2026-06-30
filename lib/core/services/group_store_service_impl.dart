import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:zapbook/core/services/group_store_service.dart';
import 'package:zapbook/core/services/marmot_sync_service.dart';

@LazySingleton(as: GroupStoreService)
class GroupStoreServiceImpl implements GroupStoreService {
  final MarmotSyncService _marmotSync;
  final Marmot _marmot;

  final _groupsController = StreamController<List<MarmotGroup>>.broadcast();
  final _groupUpdatedController = StreamController<MarmotGroup>.broadcast();

  List<MarmotGroup> _currentGroups = [];
  final Map<String, MarmotGroup> _groupsMap = {};
  Future<void>? _initFuture;
  StreamSubscription? _sub;

  GroupStoreServiceImpl(this._marmotSync, this._marmot) {
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
  Future<void> deleteGroup(String groupId) async {
    await _marmot.deleteGroup(groupId);
    _groupsMap.remove(groupId);
    _currentGroups = _groupsMap.values.toList();
    _groupsController.add(_currentGroups);
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
  void dispose() {
    _sub?.cancel();
    _groupsController.close();
    _groupUpdatedController.close();
  }
}
