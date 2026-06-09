import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reading_progress/reading_progress.dart';

import 'package:zapbook/core/services/density_service.dart';
import 'package:zapbook/features/book_reader/data/book_density_mapper.dart';
import 'package:zapbook/features/book_reader/data/reading_progress_repository.dart';
import 'package:zapbook/zbf/zbf.dart';

int _systemClock() => DateTime.now().millisecondsSinceEpoch;

class ReadingProgressCubit extends Cubit<ReadingState> {
  factory ReadingProgressCubit.forBook(
    ZbfBookHandle handle, {
    required String bookId,
    int Function()? clock,
    Duration heartbeat = const Duration(seconds: 10),
    ReadingProgressRepository? repository,
    DensityService? densityService,
  }) {
    final density = densityService?.load(bookId) ??
        bookDensityFromHandle(handle);
    return ReadingProgressCubit._(
      deps: ReadingDeps(density: density),
      bookId: bookId,
      clock: clock,
      heartbeat: heartbeat,
      repository: repository,
    );
  }

  factory ReadingProgressCubit.forDeps({
    required ReadingDeps deps,
    String bookId = '',
    int Function()? clock,
    Duration heartbeat = const Duration(seconds: 10),
    ReadingProgressRepository? repository,
  }) {
    return ReadingProgressCubit._(
      deps: deps,
      bookId: bookId,
      clock: clock,
      heartbeat: heartbeat,
      repository: repository,
    );
  }

  ReadingProgressCubit._({
    required ReadingDeps deps,
    required this.bookId,
    int Function()? clock,
    this.heartbeat = const Duration(seconds: 10),
    this.repository,
  })  : _deps = deps,
        _now = clock ?? _systemClock,
        super(ReadingState.initial(deps));

  final ReadingDeps _deps;
  final String bookId;
  final int Function() _now;
  final Duration heartbeat;
  final ReadingProgressRepository? repository;

  int get totalWords => _deps.density.totalWords;

  final _effects = StreamController<ProgressEffect>.broadcast(sync: true);
  Stream<ProgressEffect> get effects => _effects.stream;

  Timer? _timer;
  bool _paused = false;
  bool _closed = false;
  bool _dirty = false;

  Future<void> restore() async {
    final repo = repository;
    if (repo == null) return;
    final saved = await repo.loadSnapshot(bookId);
    if (saved == null) return;
    emit(state.copyWith(
      wpm: saved.wpm,
      completedPages: saved.completedPages,
      visitedPages: saved.visitedPages,
      partials: saved.partials,
      wordsRead: saved.wordsRead,
      pointsBanked: saved.pointsBanked,
      milestonesReached: saved.milestonesReached,
    ));
  }

  void start({int initialPage = 0}) {
    _dispatch(PageOpened(page: initialPage, atMs: _now()));
    _timer ??= Timer.periodic(heartbeat, (_) => tick());
  }

  void openPage(int page) =>
      _dispatch(PageOpened(page: page, atMs: _now()));

  void tap() =>
      _dispatch(Interaction(kind: InteractionKind.tap, atMs: _now()));

  void scroll({double velocity = 0}) => _dispatch(
        Interaction(
          kind: InteractionKind.scroll,
          atMs: _now(),
          scrollVelocity: velocity,
        ),
      );

  void tick() {
    if (_paused) return;
    _dispatch(Tick(atMs: _now()));
  }

  void pause() {
    if (_paused) return;
    _paused = true;
    _dispatch(AppBackgrounded(atMs: _now()));
    _save();
  }

  void resume() => _paused = false;

  void closeSession() {
    if (_closed) return;
    _closed = true;
    _timer?.cancel();
    _timer = null;
    final page = state.currentPage;
    if (page != null) {
      _dispatch(
        PageExited(page: page, direction: ExitDirection.forward, atMs: _now()),
      );
    }
    _save();
  }

  void _dispatch(ReadingEvent event) {
    if (_closed && event is! PageExited) return;
    final out = reduce(state, event, _deps);
    emit(out.state);
    for (final effect in out.effects) {
      _dirty = true;
      _effects.add(effect);
      if (effect is MilestoneReached || effect is BookCompleted) {
        _save();
      }
    }
  }

  void _save() {
    final repo = repository;
    if (repo == null || !_dirty) return;
    _dirty = false;
    unawaited(repo.saveSnapshot(bookId, state));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _timer = null;
    _effects.close();
    return super.close();
  }
}
