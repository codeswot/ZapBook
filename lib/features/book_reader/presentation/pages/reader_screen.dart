import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_loading.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_chrome_slot.dart';

import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_fade_overlay.dart';
import 'package:zapbook/zbf/zbf.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/performance/performance_service.dart';
import 'package:zapbook/core/domain/book_segment_source.dart';
import 'package:zapbook/core/domain/pdf_page_rasterizer.dart';
import 'package:zapbook/core/services/density_service.dart';
import 'package:zapbook/core/services/milestone_service.dart';
import 'package:zapbook/core/services/quiz_service.dart';
import 'package:zapbook/core/services/reading_stats_service.dart';
import 'package:zapbook/features/book_reader/data/reading_progress_repository.dart';
import 'package:zapbook/features/book_reader/data/recognition_quiz_builder.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/reader_settings/reader_settings_cubit.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/reader_settings/reader_settings_state.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/viewer/zbf_viewer_cubit.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/viewer/zbf_viewer_state.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_body.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_footer.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_header.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_pull_indicator.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_toc_sheet.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_search_sheet.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/quiz_cubit.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/reading_progress_cubit.dart';
import 'package:zapbook/theme/reading_style.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    required this.handle,
    this.rasterizer,
    this.segmentLoader,
    this.onExit,
    this.initialPage,
    this.highlightQuery,
    super.key,
  });

  final ZbfBookHandle handle;
  final PdfPageRasterizer? rasterizer;
  final BookSegmentLoader? segmentLoader;
  final VoidCallback? onExit;
  final int? initialPage;
  final String? highlightQuery;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen>
    with WidgetsBindingObserver {
  bool _chromeVisible = false;
  bool _turningForward = true;
  ReaderPullState? _pull;

  late final ReadingProgressCubit _progress;
  late final MilestoneService _milestone;
  late final Stream<BookProgress> _progressStream;
  double _lastScrollDelta = 0;
  int _savedPage = 0;
  bool _ready = false;

  final _scrollOffsets = <int, double>{};

  String? _activeQuery;
  int? _highlightPage;

  void _configureQuiz() {
    final quiz = getIt<QuizService>();
    quiz.clear();
    final builder = getIt<RecognitionQuizBuilder>();
    final bookId = widget.handle.manifest.id;
    quiz.setGenerator(
      (milestoneIdx, text) => builder.build(bookId, milestoneIdx, text),
    );
    quiz.aiAvailable = true;
  }

  void _jumpToHit(ZbfViewerCubit cubit, int page, String query) {
    setState(() {
      _activeQuery = query;
      _highlightPage = page;
    });
    cubit.goToPage(page);
  }

  String? _queryFor(int index) =>
      (_highlightPage != null && index == _highlightPage) ? _activeQuery : null;

  @override
  void initState() {
    super.initState();
    _configureQuiz();
    _progress = ReadingProgressCubit.forBook(
      widget.handle,
      bookId: widget.handle.manifest.id,
      repository: getIt<ReadingProgressRepository>(),
      densityService: getIt<DensityService>(),
      milestoneService: getIt<MilestoneService>(),
      quizService: getIt<QuizService>(),
      statsService: getIt<ReadingStatsService>(),
    );
    _milestone = getIt<MilestoneService>();
    _progressStream = _milestone.watchProgress(widget.handle.manifest.id);
    _progress.restore().then((saved) {
      if (saved.page != null) _savedPage = saved.page!;
      final so = saved.scrollOffset;
      if (so != null && saved.page != null) {
        _scrollOffsets[saved.page!] = so;
      }
      final override = widget.initialPage;
      if (override != null &&
          override >= 0 &&
          override < widget.handle.manifest.pageCount) {
        _savedPage = override;
        final query = widget.highlightQuery;
        if (query != null && query.isNotEmpty) {
          _activeQuery = query;
          _highlightPage = override;
        }
      }
      if (mounted) {
        _progress.start(initialPage: _savedPage);
        setState(() => _ready = true);
      }
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progress.closeSession();
    _progress.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.resumed) {
      _progress.resume();
    } else {
      _progress.pause();
    }
  }

  void _toggleChrome() => setState(() => _chromeVisible = !_chromeVisible);

  void _onScrollDirection(ScrollDirection direction) {
    final shouldShow = direction == ScrollDirection.forward;
    if (shouldShow != _chromeVisible) {
      setState(() => _chromeVisible = shouldShow);
    }
  }

  void _onPullChanged(ReaderPullState? pull) {
    if (pull == null && _pull == null) return;
    setState(() {
      _pull = pull;
      if (pull != null) _chromeVisible = false;
    });
  }

  List<BookBlock>? _blocksFor(int index, ZbfViewerState state) {
    final page = widget.handle.pageAt(index);
    if (page.layoutType == BookLayoutType.processing) return null;
    if (page.layoutType == BookLayoutType.illustration) {
      return state.imagePages[index] ?? page.blocks;
    }
    return page.blocks;
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Scaffold(
        backgroundColor: context.colors.paper,
        body: const ReaderPageLoading(message: 'Opening…'),
      );
    }
    final colors = context.colors;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ZbfViewerCubit(
            handle: widget.handle,
            rasterizer: widget.rasterizer,
            segmentLoader: widget.segmentLoader,
            initialPage: _savedPage,
          ),
        ),
        BlocProvider.value(value: getIt<ReaderSettingsCubit>()),
        BlocProvider(create: (_) => QuizCubit(getIt<QuizService>())..start()),
      ],
      child: Scaffold(
        backgroundColor: colors.paper,
        body: BlocListener<ZbfViewerCubit, ZbfViewerState>(
          listenWhen: (previous, current) =>
              previous.currentPage != current.currentPage,
          listener: (context, state) {
            final prev = _savedPage;
            final next = state.currentPage;
            final goingBack = next < prev;
            _progress.openPage(next);
            _savedPage = next;
            if (goingBack && !_scrollOffsets.containsKey(next)) {
              _scrollOffsets[next] = double.infinity;
            }
          },
          child: BlocBuilder<ZbfViewerCubit, ZbfViewerState>(
            builder: (context, state) {
              final cubit = context.read<ZbfViewerCubit>();
              final total = widget.handle.manifest.pageCount;
              final index = state.currentPage;
              final settings = context
                  .select<ReaderSettingsCubit, ReaderSettingsState>(
                    (c) => c.state,
                  );
              final style = ReadingStyle.of(
                settings.font,
                colors,
                textScale: settings.textScale,
              );
              final blocks = _blocksFor(index, state);
              final page = widget.handle.pageAt(index);

              return Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedSwitcher(
                      duration: getIt<PerformanceService>().reduceEffects
                          ? Duration.zero
                          : const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final isIncoming = child.key == ValueKey<int>(index);
                        final beginOffset = _turningForward
                            ? const Offset(0, 0.06)
                            : const Offset(0, -0.06);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: isIncoming ? beginOffset : Offset.zero,
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey<int>(index),
                        child: blocks == null
                            ? (state.failedPages.contains(index)
                                  ? ReaderPagePrepFailed(
                                      key: ValueKey<String>('failed_$index'),
                                      pageNumber: index + 1,
                                      onRetry: () => cubit.retryPage(index),
                                      onSkip: index < total - 1
                                          ? cubit.nextPage
                                          : null,
                                    )
                                  : ReaderPageLoading(
                                      key: ValueKey<String>('loading_$index'),
                                      message: 'Preparing page ${index + 1}…',
                                    ))
                            : (state.rasterizingPages.contains(index) &&
                                  page.layoutType ==
                                      BookLayoutType.illustration &&
                                  !state.imagePages.containsKey(index))
                            ? ReaderPageLoading(
                                key: ValueKey<String>('raster_$index'),
                                message: 'Rendering page ${index + 1}…',
                              )
                            : NotificationListener<ScrollUpdateNotification>(
                                onNotification: (n) {
                                  _lastScrollDelta = n.scrollDelta?.abs() ?? 0;
                                  return false;
                                },
                                child: ReaderBody(
                                  blocks: blocks,
                                  style: style,
                                  asset: widget.handle.asset,
                                  canGoForward: index < total - 1,
                                  canGoBack: index > 0,
                                  initialScrollOffset: _scrollOffsets[index],
                                  onScrollOffsetChanged: (offset) {
                                    _scrollOffsets[index] = offset;
                                    _progress.saveScrollOffset(offset);
                                  },
                                  onTap: () {
                                    _toggleChrome();
                                    _progress.tap();
                                  },
                                  onUserScrollDirection: (direction) {
                                    _onScrollDirection(direction);
                                    _progress.scroll(
                                      velocity: _lastScrollDelta,
                                    );
                                    _lastScrollDelta = 0;
                                  },
                                  onTurnForward: () {
                                    _turningForward = true;
                                    cubit.nextPage();
                                  },
                                  onTurnBackward: () {
                                    _turningForward = false;
                                    cubit.previousPage();
                                  },
                                  onPullChanged: _onPullChanged,
                                  highlightQuery: _queryFor(index),
                                  onHighlightComplete: () {
                                    if (mounted) {
                                      setState(() => _highlightPage = null);
                                    }
                                  },
                                ),
                              ),
                      ),
                    ),
                  ),
                  AppFadeOverlay.top(color: colors.paper, height: 130),
                  ReaderChromeSlot(
                    alignment: Alignment.topCenter,
                    visible: _chromeVisible,
                    fromTop: true,
                    child: ReaderHeader(
                      title: widget.handle.manifest.title,
                      chapterTitle: page.chapterTitle,
                      onBack: widget.onExit ?? () => context.pop(),
                      onSearch: () => ReaderSearchSheet.show(
                        context,
                        bookId: widget.handle.manifest.id,
                        onSelect: (hitPage, query) =>
                            _jumpToHit(cubit, hitPage, query),
                      ),
                      onOpenContents: () => ReaderTocSheet.show(
                        context,
                        manifest: widget.handle.manifest,
                        currentPage: index,
                        onSelect: cubit.goToPage,
                      ),
                    ),
                  ),
                  AppFadeOverlay.bottom(color: colors.paper, height: 135),

                  ReaderChromeSlot(
                    alignment: Alignment.bottomCenter,
                    visible: _chromeVisible,
                    fromTop: false,
                    child: StreamBuilder<BookProgress>(
                      stream: _progressStream,
                      initialData: _milestone.progressOf(
                        widget.handle.manifest.id,
                      ),
                      builder: (context, snapshot) => ReaderFooter(
                        progress: snapshot.data?.fraction ?? 0,
                        currentPage: index,
                        totalPages: total,
                      ),
                    ),
                  ),
                  ReaderPullIndicator(pull: _pull),
                  BlocBuilder<QuizCubit, QuizCubitState>(
                    builder: (context, quizState) {
                      if (quizState.screen == QuizScreenState.idle ||
                          quizState.screen == QuizScreenState.done) {
                        return const SizedBox.shrink();
                      }
                      return _QuizPill(state: quizState);
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _QuizPill extends StatelessWidget {
  const _QuizPill({required this.state});

  final QuizCubitState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QuizCubit>();
    return Positioned(
      bottom: 150,
      left: 20,
      right: 20,
      child: Material(
        color: context.colors.transparent,
        child: state.screen == QuizScreenState.reveal
            ? _QuizReveal(state: state, cubit: cubit)
            : _QuizActive(state: state, cubit: cubit),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.paper3,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.hairline2),
        boxShadow: [
          BoxShadow(
            color: colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _QuizActive extends StatelessWidget {
  const _QuizActive({required this.state, required this.cubit});

  final QuizCubitState state;
  final QuizCubit cubit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final set = state.set;
    if (set == null || state.currentIndex >= set.questions.length) {
      return const SizedBox.shrink();
    }
    final question = set.questions[state.currentIndex];

    return _QuizCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'COMPREHENSION · ${state.currentIndex + 1}/${set.questions.length}',
                style: typography.caption.copyWith(
                  color: colors.bitcoin,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              GestureDetector(
                onTap: cubit.skip,
                child: Text(
                  'Skip',
                  style: typography.bodyS.copyWith(
                    color: colors.slate,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            question.text,
            style: typography.bodyL.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < question.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: BouncingInteractiveWidget(
                onTap: () => cubit.answer(i),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colors.paper,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.hairline2),
                  ),
                  child: Text(
                    question.options[i],
                    style: typography.bodyS.copyWith(color: colors.ink),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuizReveal extends StatelessWidget {
  const _QuizReveal({required this.state, required this.cubit});

  final QuizCubitState state;
  final QuizCubit cubit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final pct = ((state.score ?? 0) * 100).round();
    final total = state.set?.questions.length ?? 0;
    final correct = ((state.score ?? 0) * total).round();

    return _QuizCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$pct%',
                  style: typography.h2.copyWith(
                    color: colors.bitcoin,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$correct of $total recalled',
                  style: typography.bodyS.copyWith(color: colors.slate),
                ),
              ],
            ),
          ),
          BouncingInteractiveWidget(
            onTap: cubit.dismiss,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: colors.bitcoin,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Done',
                style: typography.bodyS.copyWith(
                  color: colors.bitcoinDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
