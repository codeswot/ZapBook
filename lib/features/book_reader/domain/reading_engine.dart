import 'package:reading_progress/reading_progress.dart';

import 'package:zapbook/features/book_reader/data/book_density_mapper.dart';
import 'package:zapbook/zbf/zbf.dart';

int _systemClock() => DateTime.now().millisecondsSinceEpoch;

ProgressConfig configFor(int totalWords, BookSourceFormat format) {
  final isEpub = format == BookSourceFormat.epub;
  if (totalWords >= 900) {
    if (isEpub) {
      return const ProgressConfig(
        k: 0.15,
        skimRatio: 1.0,
        skimVelocity: 999999.0,
      );
    }
    return const ProgressConfig();
  }
  final unit = (totalWords / 3).ceil().clamp(1, 300);
  if (isEpub) {
    return ProgressConfig(
      wordUnitSize: unit,
      milestoneThresholdUnits: 1,
      k: 0.15,
      skimRatio: 1.0,
      skimVelocity: 999999.0,
    );
  }
  return ProgressConfig(wordUnitSize: unit, milestoneThresholdUnits: 1);
}

class ReadingEngine {
  ReadingEngine({required ReadingDeps deps, int Function()? clock})
    : _deps = deps,
      _now = clock ?? _systemClock,
      _state = ReadingState.initial(deps);

  factory ReadingEngine.forBook(ZbfBookHandle handle, {int Function()? clock}) {
    final density = bookDensityFromHandle(handle);
    final config = configFor(density.totalWords, handle.manifest.sourceFormat);
    return ReadingEngine(
      deps: ReadingDeps(density: density, config: config),
      clock: clock,
    );
  }

  final ReadingDeps _deps;
  final int Function() _now;
  ReadingState _state;

  ReadingState get state => _state;
  ReadingDeps get deps => _deps;
  BookDensity get density => _deps.density;
  int get totalWords => _deps.density.totalWords;

  double get wordProgress =>
      totalWords > 0 ? (_state.wordsRead / totalWords).clamp(0.0, 1.0) : 0;

  void seed(ReadingState state) => _state = state;

  List<ProgressEffect> openPage(int page) =>
      _apply(PageOpened(page: page, atMs: _now()));

  List<ProgressEffect> tap() =>
      _apply(Interaction(kind: InteractionKind.tap, atMs: _now()));

  List<ProgressEffect> scroll({double velocity = 0}) => _apply(
    Interaction(
      kind: InteractionKind.scroll,
      atMs: _now(),
      scrollVelocity: velocity,
    ),
  );

  List<ProgressEffect> tick() => _apply(Tick(atMs: _now()));

  List<ProgressEffect> background() => _apply(AppBackgrounded(atMs: _now()));

  List<ProgressEffect> exitPage(int page, ExitDirection direction) =>
      _apply(PageExited(page: page, direction: direction, atMs: _now()));

  List<ProgressEffect> _apply(ReadingEvent event) {
    final out = reduce(_state, event, _deps);
    _state = out.state;
    return out.effects;
  }
}
