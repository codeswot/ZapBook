import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:reading_progress/reading_progress.dart';
import 'package:zapbook/core/domain/usecases/watch_my_reading_progress.dart';
import 'package:zapbook/core/domain/entities/reading_progress.dart';

import 'package:zapbook/features/book_reader/domain/usecases/book_reader_usecases.dart';
import 'package:zapbook/features/book_reader/domain/reading_engine.dart';
import 'package:zapbook/features/home/domain/usecases/touch_dashboard_book_opened.dart';
import 'package:zapbook/zbf/zbf.dart';

part 'reading_progress_state.dart';

const defaultHeartbeat = Duration(seconds: 10);

@injectable
class ReadingProgressCubit extends Cubit<ReadingProgressState> {
  ReadingProgressCubit(
    this._saveSnapshot,
    this._loadSnapshot,
    this._reportProgress,
    this._watchProgressUseCase,
    this._touchOpened,
  ) : super(const ReadingProgressState());

  final SaveReadingSnapshotUseCase _saveSnapshot;
  final LoadReadingSnapshotUseCase _loadSnapshot;
  final ReportReadingProgressUseCase _reportProgress;
  final WatchMyReadingProgressUseCase _watchProgressUseCase;
  final TouchDashboardBookOpened _touchOpened;

  late final ReadingEngine _engine;
  late final String _circleDirId;
  late final String _groupId;
  Duration _heartbeat = defaultHeartbeat;
  Timer? _timer;
  bool _paused = false;
  bool _closed = false;
  bool _dirty = false;
  double? _lastScrollOffset;

  int get totalWords => _engine.totalWords;
  double get wordProgress => _engine.wordProgress;

  Stream<ReadingProgress?> watchProgress() {
    return _watchProgressUseCase(groupId: _groupId, bookId: _circleDirId);
  }

  void open(
    ZbfBookHandle handle, {
    required String circleDirId,
    required String groupId,
    int Function()? clock,
    Duration heartbeat = defaultHeartbeat,
  }) {
    _circleDirId = circleDirId;
    _groupId = groupId;
    _heartbeat = heartbeat;
    _touchOpened(_circleDirId);
    _engine = ReadingEngine.forBook(handle, clock: clock);
    emit(_project());
  }

  Future<({int? page, double? scrollOffset})> restore() async {
    final saved = await _loadSnapshot(_circleDirId);
    if (saved == null) return (page: null, scrollOffset: null);
    _engine.seed(
      _engine.state.copyWith(
        wpm: saved.state.wpm,
        completedPages: saved.state.completedPages,
        visitedPages: saved.state.visitedPages,
        partials: saved.state.partials,
        wordsRead: saved.state.wordsRead,
        pointsBanked: saved.state.pointsBanked,
        milestonesReached: saved.state.milestonesReached,
      ),
    );
    emit(_project());
    return (page: saved.state.currentPage, scrollOffset: saved.scrollOffset);
  }

  void start({int initialPage = 0}) {
    if (_closed) return;
    _run(_engine.openPage(initialPage));
    _report();
    _timer ??= Timer.periodic(_heartbeat, (_) => tick());
  }

  void openPage(int page) {
    if (_closed) return;
    _run(_engine.openPage(page));
    _report();
    _dirty = true;
  }

  void tap() {
    if (_closed) return;
    _run(_engine.tap());
  }

  void scroll({double velocity = 0}) {
    if (_closed) return;
    _run(_engine.scroll(velocity: velocity));
  }

  void tick() {
    if (_paused || _closed) return;
    _run(_engine.tick());
    if (_dirty) _save();
  }

  void pause() {
    if (_paused) return;
    _paused = true;
    if (!_closed) _run(_engine.background());
    _save();
  }

  void resume() => _paused = false;

  void closeSession() {
    if (_closed) return;
    _closed = true;
    _timer?.cancel();
    _timer = null;
    final page = _engine.state.currentPage;
    if (page != null) {
      _run(_engine.exitPage(page, ExitDirection.forward));
    }
    _reportProgress.close(_circleDirId);
    _save();
  }

  /// Lets the reader jump straight to "finished" from the floating
  /// mark-as-complete pill, instead of waiting for the engine to detect
  /// completion page-by-page. We fast-forward the word count to the end
  /// of the book and replay it through the same exit-page transition
  /// [closeSession] uses, so page bookkeeping (visited/completed pages,
  /// milestones) stays consistent with a normal finish — then force
  /// `bookCompleted` to true as a safeguard, since the engine's own
  /// completion detection may key off more than just word count.
  void markComplete() {
    if (_closed || state.bookCompleted) return;
    final total = totalWords;
    if (total <= 0) return;
    _engine.seed(_engine.state.copyWith(wordsRead: total));
    final page = _engine.state.currentPage;
    if (page != null) {
      _run(_engine.exitPage(page, ExitDirection.forward));
    } else {
      _run(_engine.tick());
    }
    _engine.seed(_engine.state.copyWith(bookCompleted: true));
    emit(_project());
    _dirty = true;
    _save();
    _report();
  }

  void _run(List<ProgressEffect> effects) {
    emit(_project());
    _handleEffects(effects);
  }

  ReadingProgressState _project() => ReadingProgressState(
    fraction: _engine.wordProgress,
    currentPage: _engine.state.currentPage ?? 0,
    wordsRead: _engine.state.wordsRead,
    bookCompleted: _engine.state.bookCompleted,
  );

  void _handleEffects(List<ProgressEffect> effects) {
    for (final effect in effects) {
      _dirty = true;
      if (effect is PageCompleted) {
        _reportProgress.flush(_circleDirId);
      }
      if (effect is MilestoneReached) {
        _save();
        _report();
      }
      if (effect is BookCompleted) {
        _save();
        _report();
      }
    }
  }

  void _report() {
    _reportProgress.report(
      circleDirId: _circleDirId,
      groupId: _groupId,
      currentPage: _engine.state.currentPage ?? 0,
      currentWordCount: _engine.state.wordsRead,
      totalWords: totalWords,
      fraction: wordProgress,
      milestonesReached: _engine.state.milestonesReached,
      bookCompleted: _engine.state.bookCompleted,
    );
  }

  void saveScrollOffset(double offset) {
    _lastScrollOffset = offset;
    _dirty = true;
  }

  void _save() {
    if (!_dirty) return;
    _dirty = false;
    unawaited(
      _saveSnapshot(
        _circleDirId,
        _engine.state,
        scrollOffset: _lastScrollOffset,
      ),
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _timer = null;
    return super.close();
  }
}
