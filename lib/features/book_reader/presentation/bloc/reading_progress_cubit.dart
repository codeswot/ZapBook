import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reading_progress/reading_progress.dart';

import 'package:zapbook/core/services/density_service.dart';
import 'package:zapbook/core/services/milestone_service.dart';
import 'package:zapbook/core/services/quiz_service.dart';
import 'package:zapbook/core/services/reading_stats_service.dart';
import 'package:zapbook/features/book_reader/data/book_density_mapper.dart';
import 'package:zapbook/features/book_reader/data/reading_progress_repository.dart';
import 'package:zapbook/zbf/zbf.dart';
import 'package:zapbook/core/domain/quiz_models.dart';

int _systemClock() => DateTime.now().millisecondsSinceEpoch;

ProgressConfig _configFor(int totalWords, BookSourceFormat format) {
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

class ReadingProgressCubit extends Cubit<ReadingState> {
  factory ReadingProgressCubit.forBook(
    ZbfBookHandle handle, {
    required String bookId,
    int Function()? clock,
    Duration heartbeat = const Duration(seconds: 10),
    ReadingProgressRepository? repository,
    DensityService? densityService,
    MilestoneService? milestoneService,
    QuizService? quizService,
    ReadingStatsService? statsService,
  }) {
    final density = bookDensityFromHandle(handle);
    final config = _configFor(density.totalWords, handle.manifest.sourceFormat);
    return ReadingProgressCubit._(
      deps: ReadingDeps(density: density, config: config),
      bookId: bookId,
      clock: clock,
      heartbeat: heartbeat,
      repository: repository,
      milestoneService: milestoneService,
      quizService: quizService,
      statsService: statsService,
      handle: handle,
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
    this.milestoneService,
    this.quizService,
    this.statsService,
    this._handle,
  }) : _deps = deps,
       _now = clock ?? _systemClock,
       super(ReadingState.initial(deps)) {
    _quizSub = quizService?.onCompleted.listen((result) {
      if (result.score == 1.0) {}
    });
  }

  final ReadingDeps _deps;
  final String bookId;
  final int Function() _now;
  final Duration heartbeat;
  final ReadingProgressRepository? repository;
  final MilestoneService? milestoneService;
  final QuizService? quizService;
  final ReadingStatsService? statsService;
  final ZbfBookHandle? _handle;

  int get totalWords => _deps.density.totalWords;

  double get wordProgress =>
      totalWords > 0 ? (state.wordsRead / totalWords).clamp(0.0, 1.0) : 0;

  final _effects = StreamController<ProgressEffect>.broadcast(sync: true);
  Stream<ProgressEffect> get effects => _effects.stream;

  Timer? _timer;
  Timer? _saveTimer;
  StreamSubscription<QuizResult>? _quizSub;
  bool _paused = false;
  bool _closed = false;
  bool _dirty = false;
  final _publishedMilestones = <int>{};

  Future<int?> restore() async {
    final repo = repository;
    if (repo == null) return null;
    final saved = await repo.loadSnapshot(bookId);
    if (saved == null) return null;
    emit(
      state.copyWith(
        wpm: saved.wpm,
        completedPages: saved.completedPages,
        visitedPages: saved.visitedPages,
        partials: saved.partials,
        wordsRead: saved.wordsRead,
        pointsBanked: saved.pointsBanked,
        milestonesReached: saved.milestonesReached,
      ),
    );
    for (var i = 0; i < saved.milestonesReached; i++) {
      _publishedMilestones.add(i);
    }
    return saved.currentPage;
  }

  void start({int initialPage = 0}) {
    _dispatch(PageOpened(page: initialPage, atMs: _now()));
    milestoneService?.updateProgress(
      bookId: bookId,
      currentPage: initialPage,
      currentWordCount: state.wordsRead,
      totalWords: totalWords,
      fraction: wordProgress,
    );
    _timer ??= Timer.periodic(heartbeat, (_) => tick());
  }

  void openPage(int page) {
    _dispatch(PageOpened(page: page, atMs: _now()));
    milestoneService?.updateProgress(
      bookId: bookId,
      currentPage: page,
      currentWordCount: state.wordsRead,
      totalWords: totalWords,
      fraction: wordProgress,
    );
    _dirty = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      _save();
    });
  }

  void tap() => _dispatch(Interaction(kind: InteractionKind.tap, atMs: _now()));

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
    quizService?.onPause();
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
    quizService?.onPause();
  }

  void _dispatch(ReadingEvent event) {
    if (_closed && event is! PageExited) return;
    final out = reduce(state, event, _deps);
    emit(out.state);
    for (final effect in out.effects) {
      _dirty = true;
      _effects.add(effect);
      if (effect is MilestoneReached) {
        _save();
        _publishMilestone(effect);
        _stashQuiz(effect);
        statsService?.recordMilestone();
      }
      if (effect is BookCompleted) {
        _save();
        milestoneService?.recordBookCompleted(bookId);
        unawaited(
          milestoneService?.markCompleted(bookId, totalWords: totalWords),
        );
        unawaited(milestoneService?.publishBookCompleted(bookId));
        statsService?.recordBookCompleted();
      }
    }
  }

  void _publishMilestone(MilestoneReached effect) {
    if (_publishedMilestones.contains(effect.index)) return;
    _publishedMilestones.add(effect.index);
    milestoneService?.publishMilestone(
      bookId: bookId,
      milestoneIdx: effect.index,
      currentWordCount: effect.wordsRead,
      totalWordCount: totalWords,
      progressPct: totalWords > 0 ? (effect.wordsRead / totalWords) * 100 : 0,
      currentPage: state.currentPage ?? 0,
      sessionEngagedMs: state.sessionEngagedMs,
    );
  }

  void _stashQuiz(MilestoneReached effect) {
    final qs = quizService;
    if (qs == null) return;
    final handle = _handle;
    if (handle == null) return;
    final text = extractMilestoneText(handle, _deps.density, effect.index);
    qs.stashMilestone(effect.index, effect.wordsRead, state.pointsBanked, text);
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
    _saveTimer?.cancel();
    _quizSub?.cancel();
    _timer = null;
    _saveTimer = null;
    _quizSub = null;
    _effects.close();
    return super.close();
  }
}
