import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reading_progress/reading_progress.dart';

import 'package:zapbook/features/book_reader/data/book_density_mapper.dart';
import 'package:zapbook/zbf/zbf.dart';

int _systemClock() => DateTime.now().millisecondsSinceEpoch;

class ReadingProgressCubit extends Cubit<ReadingState> {
  factory ReadingProgressCubit.forBook(
    ZbfBookHandle handle, {
    int Function()? clock,
    Duration heartbeat = const Duration(seconds: 10),
  }) {
    final deps = ReadingDeps(density: bookDensityFromHandle(handle));
    return ReadingProgressCubit._(
      deps: deps,
      clock: clock,
      heartbeat: heartbeat,
    );
  }

  factory ReadingProgressCubit.forDeps({
    required ReadingDeps deps,
    int Function()? clock,
    Duration heartbeat = const Duration(seconds: 10),
  }) {
    return ReadingProgressCubit._(
      deps: deps,
      clock: clock,
      heartbeat: heartbeat,
    );
  }

  ReadingProgressCubit._({
    required ReadingDeps deps,
    int Function()? clock,
    this.heartbeat = const Duration(seconds: 10),
  })  : _deps = deps,
        _now = clock ?? _systemClock,
        super(ReadingState.initial(deps));

  final ReadingDeps _deps;
  final int Function() _now;
  final Duration heartbeat;

  final _effects = StreamController<ProgressEffect>.broadcast(sync: true);
  Stream<ProgressEffect> get effects => _effects.stream;

  Timer? _timer;
  bool _paused = false;
  bool _closed = false;

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
  }

  void _dispatch(ReadingEvent event) {
    if (_closed && event is! PageExited) return;
    final out = reduce(state, event, _deps);
    emit(out.state);
    for (final effect in out.effects) {
      _effects.add(effect);
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _timer = null;
    _effects.close();
    return super.close();
  }
}
