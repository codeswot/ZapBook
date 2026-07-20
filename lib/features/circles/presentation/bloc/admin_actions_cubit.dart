import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging show Logger;

import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/core/domain/entities/pending_circle_upload.dart';
import 'package:zapbook/features/circles/domain/entities/admin_action_item.dart';
import 'package:zapbook/features/circles/domain/usecases/circles_usecases.dart';
import 'package:zapbook/features/circles/presentation/bloc/admin_actions_state.dart';

@injectable
class AdminActionsCubit extends Cubit<AdminActionsState> {
  AdminActionsCubit(
    this._getMyNpubUseCase,
    this._watchPendingUploadsUseCase,
    this._getReseedRequestersUseCase,
    this._retryPendingUploadUseCase,
    this._reseedCircleBookUseCase,
    this._markAdminActionsAsReadUseCase,
  ) : super(const AdminActionsLoading());
  final GetMyNpubUseCase _getMyNpubUseCase;
  final WatchPendingCircleUploadsUseCase _watchPendingUploadsUseCase;
  final GetReseedRequestersUseCase _getReseedRequestersUseCase;
  final RetryPendingCircleUploadUseCase _retryPendingUploadUseCase;
  final ReseedCircleBookUseCase _reseedCircleBookUseCase;
  final MarkAdminActionsAsReadUseCase _markAdminActionsAsReadUseCase;

  final _log = logging.Logger('AdminActionsCubit');
  StreamSubscription<List<PendingCircleUpload>>? _pendingSub;
  String? _myNpub;
  CircleBook? _currentBook;

  Future<void> load(CircleBook book) async {
    emit(const AdminActionsLoading());

    final myNpub = await _getMyNpubUseCase();
    if (myNpub == null) {
      emit(const AdminActionsLoaded(items: []));
      return;
    }
    _myNpub = myNpub;
    _currentBook = book;

    unawaited(_markAdminActionsAsReadUseCase(myNpub, book.circleDirId));

    await _pendingSub?.cancel();
    _pendingSub = _watchPendingUploadsUseCase(myNpub).listen((pending) {
      unawaited(_rebuild(pending));
    });
  }

  Future<void> refresh() async {
    final npub = _myNpub;
    if (npub == null) return;
    final pending = await _watchPendingUploadsUseCase(npub).first;
    await _rebuild(pending);
  }

  Future<void> _rebuild(List<PendingCircleUpload> pending) async {
    final npub = _myNpub;
    final book = _currentBook;
    if (npub == null || book == null || isClosed) return;

    final upload = pending
        .where((u) => u.circleDirId == book.circleDirId)
        .firstOrNull;
    final requesters = await _getReseedRequestersFor(book);

    if (isClosed) return;

    final item = AdminActionItem(
      book: book,
      pendingUpload: upload,
      reseedRequesterNpubs: requesters,
    );

    final actionable = (item.hasFailedUpload || item.hasReseedRequests)
        ? [item]
        : <AdminActionItem>[];
    emit(AdminActionsLoaded(items: actionable));
  }

  Future<List<String>> _getReseedRequestersFor(CircleBook book) async {
    try {
      return await _getReseedRequestersUseCase(
        groupId: book.id,
        circleDirId: book.circleDirId,
      );
    } on Object catch (error, stack) {
      _log.warning(
        'Failed to load reseed requesters for ${book.id}',
        error,
        stack,
      );
      return [];
    }
  }

  Future<void> retryUpload(AdminActionItem item) async {
    final upload = item.pendingUpload;
    if (upload == null) return;
    await _setBusy(item.book.circleDirId, true);
    try {
      await _retryPendingUploadUseCase(upload);
    } finally {
      await _setBusy(item.book.circleDirId, false);
    }
    await refresh();
  }

  Future<void> reseed(AdminActionItem item) async {
    final npub = _myNpub;
    if (npub == null) return;
    await _setBusy(item.book.circleDirId, true);
    try {
      await _reseedCircleBookUseCase(
        groupId: item.book.id,
        circleDirId: item.book.circleDirId,
        myNpub: npub,
      );
    } finally {
      await _setBusy(item.book.circleDirId, false);
    }
    await refresh();
  }

  Future<void> _setBusy(String circleDirId, bool busy) async {
    final s = state;
    if (s is! AdminActionsLoaded || isClosed) return;
    final ids = Set<String>.from(s.busyCircleDirIds);
    if (busy) {
      ids.add(circleDirId);
    } else {
      ids.remove(circleDirId);
    }
    emit(AdminActionsLoaded(items: s.items, busyCircleDirIds: ids));
  }

  @override
  Future<void> close() {
    _pendingSub?.cancel();
    return super.close();
  }
}
