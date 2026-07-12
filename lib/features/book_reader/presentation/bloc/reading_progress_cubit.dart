import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:reading_progress/reading_progress.dart';
import 'package:zapbook/core/domain/usecases/watch_my_reading_progress.dart';
import 'package:zapbook/core/domain/entities/reading_progress.dart';

import 'package:zapbook/core/services/milestone_service.dart';
import 'package:zapbook/core/services/reading_stats_service.dart';
import 'package:zapbook/features/book_reader/data/reading_progress_local_store.dart';
import 'package:zapbook/features/book_reader/domain/reading_engine.dart';
import 'package:zapbook/zbf/zbf.dart';

part 'reading_progress_state.dart';

const defaultHeartbeat = Duration(seconds: 10);

@injectable
class ReadingProgressCubit extends Cubit<ReadingProgressState> {
  ReadingProgressCubit(
    this._localReadingProgressStore,
    this._watchProgressUseCase,
    this._milestoneService,
    this._statsService,
  ) : super(const ReadingProgressState());

  final ReadingProgressLocalStore _localReadingProgressStore;
  final WatchMyReadingProgressUseCase _watchProgressUseCase;
  final MilestoneService _milestoneService;
  final ReadingStatsService _statsService;

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
    _engine = ReadingEngine.forBook(handle, clock: clock);
    emit(_project());
  }

  Future<({int? page, double? scrollOffset})> restore() async {
    final saved = await _localReadingProgressStore.loadSnapshot(_circleDirId);
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
    _milestoneService.closeBook(_circleDirId);
    _save();
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
        _milestoneService.flushProgress(_circleDirId);
      }
      if (effect is MilestoneReached) {
        _save();
        _report();
        _statsService.recordMilestone();
      }
      if (effect is BookCompleted) {
        _save();
        _report();
      }
    }
  }

  void _report() {
    _milestoneService.reportProgress(
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
      _localReadingProgressStore.saveSnapshot(
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
