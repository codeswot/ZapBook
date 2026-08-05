import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging show Logger;

import 'package:zapbook/features/circles/domain/entities/share_skip.dart';
import 'package:zapbook/features/circles/domain/usecases/circles_usecases.dart';
import 'package:zapbook/features/circles/presentation/bloc/share_circle_state.dart';

@injectable
class ShareCircleCubit extends Cubit<ShareCircleState> {
  ShareCircleCubit(
    this._getFriendsUseCase,
    this._getCircleBookUseCase,
    this._getExistingMemberNpubsUseCase,
    this._shareUseCase,
    this._getMyNpubUseCase,
    this._watchActiveUploadsUseCase,
    this._watchPendingCircleUploadsUseCase,
    this._uploadCircleBookUseCase,
  ) : super(const ShareCircleLoading());

  final GetFriendsUseCase _getFriendsUseCase;
  final GetCircleBookUseCase _getCircleBookUseCase;
  final GetExistingMemberNpubsUseCase _getExistingMemberNpubsUseCase;
  final ShareCircleBookUseCase _shareUseCase;
  final GetMyNpubUseCase _getMyNpubUseCase;
  final WatchActiveUploadsUseCase _watchActiveUploadsUseCase;
  final WatchPendingCircleUploadsUseCase _watchPendingCircleUploadsUseCase;
  final UploadCircleBookUseCase _uploadCircleBookUseCase;

  StreamSubscription? _uploadSub;
  String? _circleDirId;
  String? _circleBookId;

  final _log = logging.Logger('ShareCircleCubit');

  bool isValidNpub(String value) {
    if (value.isEmpty) return false;
    final npubRegex = RegExp(r'^npub1[02-9ac-hj-np-z]{58}$');
    return npubRegex.hasMatch(value);
  }

  Future<void> load(String circleBookId) async {
    _circleBookId = circleBookId;
    final friends = await _getFriendsUseCase();

    final book = await _getCircleBookUseCase(circleBookId);
    var existingMembers = <String>{};

    if (book != null && book.id.isNotEmpty) {
      _circleDirId = book.circleDirId;
      existingMembers = await _getExistingMemberNpubsUseCase(circleBookId);
    }

    _subscribeToUploadStatus();

    emit(
      ShareCircleLoaded(
        friends: friends,
        selectedNpubs: const [],
        existingMembers: existingMembers,
        uploadStatus: _calculateUploadStatus(_circleDirId, {}, []),
      ),
    );
  }

  UploadStatus _calculateUploadStatus(
    String? dirId,
    Set<String> active,
    List<dynamic> pending,
  ) {
    if (dirId == null) return UploadStatus.uploaded;
    if (active.contains(dirId)) return UploadStatus.uploading;
    if (pending.any((p) => p.circleDirId == dirId)) return UploadStatus.pending;
    return UploadStatus.uploaded;
  }

  void _subscribeToUploadStatus() async {
    final myNpub = await _getMyNpubUseCase();
    if (myNpub == null) return;

    Set<String> active = {};
    List<dynamic> pending = [];

    void updateState() {
      final s = state;
      final status = _calculateUploadStatus(_circleDirId, active, pending);

      if (s is ShareCircleLoaded) {
        emit(
          ShareCircleLoaded(
            friends: s.friends,
            selectedNpubs: s.selectedNpubs,
            existingMembers: s.existingMembers,
            uploadStatus: status,
            shareResult: s.shareResult,
          ),
        );
      } else if (s is ShareCircleBusy) {
        emit(
          ShareCircleBusy(
            friends: s.friends,
            selectedNpubs: s.selectedNpubs,
            existingMembers: s.existingMembers,
            uploadStatus: status,
            adding: s.adding,
            sharing: s.sharing,
          ),
        );
      }
    }

    _watchActiveUploadsUseCase().listen((a) {
      active = a;
      updateState();
    });

    _watchPendingCircleUploadsUseCase(myNpub).listen((p) {
      pending = p;
      updateState();
    });
  }

  @override
  Future<void> close() {
    _uploadSub?.cancel();
    return super.close();
  }

  void toggleNpub(String npub) {
    final s = state;
    if (s is! ShareCircleLoaded) return;

    final current = List<String>.from(s.selectedNpubs);
    if (current.contains(npub)) {
      current.remove(npub);
    } else {
      current.add(npub);
    }

    emit(
      ShareCircleLoaded(
        friends: s.friends,
        selectedNpubs: current,
        existingMembers: s.existingMembers,
        uploadStatus: s.uploadStatus,
      ),
    );
  }

  Future<void> addNpub(String npub) async {
    final s = state;
    if (s is! ShareCircleLoaded) return;

    emit(
      ShareCircleBusy(
        friends: s.friends,
        selectedNpubs: s.selectedNpubs,
        existingMembers: s.existingMembers,
        uploadStatus: s.uploadStatus,
        adding: true,
      ),
    );

    final current = List<String>.from(s.selectedNpubs);
    if (!current.contains(npub)) {
      current.add(npub);
    }

    emit(
      ShareCircleLoaded(
        friends: s.friends,
        selectedNpubs: current,
        existingMembers: s.existingMembers,
        uploadStatus: s.uploadStatus,
      ),
    );
  }

  Future<List<ShareSkip>> share(String circleBookId) async {
    final s = state;
    if (s is! ShareCircleLoaded) return [];
    if (s.selectedNpubs.isEmpty) return [];

    final myNpub = await _getMyNpubUseCase();
    if (myNpub == null) return [];

    emit(
      ShareCircleBusy(
        friends: s.friends,
        selectedNpubs: s.selectedNpubs,
        existingMembers: s.existingMembers,
        uploadStatus: s.uploadStatus,
        sharing: true,
      ),
    );

    try {
      final skips = await _shareUseCase(
        circleBookId: circleBookId,
        npubs: s.selectedNpubs,
        myNpub: myNpub,
      );

      if (!isClosed) {
        emit(
          ShareCircleLoaded(
            friends: s.friends,
            selectedNpubs: const [],
            existingMembers: s.existingMembers,
            uploadStatus: s.uploadStatus,
            shareResult: skips,
          ),
        );
      }

      return skips;
    } catch (e, stack) {
      _log.severe('Failed to share circle book', e, stack);

      if (!isClosed) {
        emit(
          ShareCircleLoaded(
            friends: s.friends,
            selectedNpubs: s.selectedNpubs,
            existingMembers: s.existingMembers,
            uploadStatus: s.uploadStatus,
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> upload() async {
    if (_circleBookId == null) return;
    final myNpub = await _getMyNpubUseCase();
    if (myNpub == null) return;

    await _uploadCircleBookUseCase(myNpub, _circleBookId!);
  }
}
