import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_chrome_slot.dart';

import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/core/presentation/widgets/app_fade_overlay.dart';
import 'package:zapbook/zbf/zbf.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/domain/book_segment_source.dart';
import 'package:zapbook/core/domain/usecases/pdf_usecases.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/highlights/highlights_cubit.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/book_highlights_sheet.dart';
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
import 'package:zapbook/features/book_reader/presentation/widgets/reader_opening_scaffold.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_page_view.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_mark_complete_pill.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/reading_progress_cubit.dart';
import 'package:zapbook/core/presentation/theme/reading_style.dart';
import 'package:zapbook/core/presentation/widgets/app_toast.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    required this.handle,
    required this.groupId,
    this.rasterizePdfPage,
    this.segmentLoader,
    this.onExit,
    this.initialPage,
    this.highlightQuery,
    super.key,
  });

  final ZbfBookHandle handle;
  final String groupId;
  final RasterizePdfPageUseCase? rasterizePdfPage;
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

  double _lastScrollDelta = 0;
  int _savedPage = 0;
  bool _ready = false;

  final _scrollOffsets = <int, double>{};

  String? _activeQuery;
  int? _highlightPage;

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
    final progress = context.read<ReadingProgressCubit>();
    progress.restore().then((saved) {
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
        progress.start(initialPage: _savedPage);
        setState(() => _ready = true);
      }
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.resumed) {
      context.read<ReadingProgressCubit>().resume();
    } else {
      context.read<ReadingProgressCubit>().pause();
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
    final colors = context.colors;

    if (!_ready) {
      return ReaderOpeningScaffold(
        title: widget.handle.manifest.title,
        totalPages: widget.handle.manifest.pageCount,
        chromeVisible: _chromeVisible,
        onTap: () {
          _toggleChrome();
          context.read<ReadingProgressCubit>().tap();
        },
        onBack: widget.onExit ?? () => context.pop(),
      );
    }
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ZbfViewerCubit(
            handle: widget.handle,
            rasterizePdfPage: widget.rasterizePdfPage,
            segmentLoader: widget.segmentLoader,
            initialPage: _savedPage,
          ),
        ),
        BlocProvider.value(value: getIt<ReaderSettingsCubit>()),
        BlocProvider(
          create: (_) => getIt<HighlightsCubit>()
            ..openPage(
              bookId: widget.handle.manifest.id,
              pageNumber: widget.handle.pageAt(_savedPage).pageNumber,
            ),
        ),
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
            context.read<ReadingProgressCubit>().openPage(next);
            context.read<HighlightsCubit>().openPage(
              bookId: widget.handle.manifest.id,
              pageNumber: widget.handle.pageAt(next).pageNumber,
            );
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
                    child: ReaderPageView(
                      state: state,
                      blocks: blocks,
                      page: page,
                      index: index,
                      total: total,
                      bookId: widget.handle.manifest.id,
                      groupId: widget.groupId,
                      bookTitle: widget.handle.manifest.title,
                      style: style,
                      scrollDirection: settings.scrollDirection,
                      turningForward: _turningForward,
                      asset: widget.handle.assetNamedAsync,
                      initialScrollOffset: _scrollOffsets[index],
                      highlightQuery: _queryFor(index),
                      onTapChrome: () {
                        _toggleChrome();
                        context.read<ReadingProgressCubit>().tap();
                      },
                      onRetry: () => cubit.retryPage(index),
                      onSkip: index < total - 1 ? cubit.nextPage : null,
                      onScrollDelta: (delta) => _lastScrollDelta = delta,
                      onScrollOffsetChanged: (offset) {
                        _scrollOffsets[index] = offset;
                        context.read<ReadingProgressCubit>().saveScrollOffset(
                          offset,
                        );
                      },
                      onUserScrollDirection: (direction) {
                        _onScrollDirection(direction);
                        context.read<ReadingProgressCubit>().scroll(
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
                      onHighlightComplete: () {
                        if (mounted) {
                          setState(() => _highlightPage = null);
                        }
                      },
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
                        circleDirId: widget.handle.manifest.id,
                        onSelect: (hitPage, query) =>
                            _jumpToHit(cubit, hitPage, query),
                      ),
                      onOpenContents: () => ReaderTocSheet.show(
                        context,
                        manifest: widget.handle.manifest,
                        currentPage: index,
                        onSelect: cubit.goToPage,
                      ),
                      onOpenHighlights: () => BookHighlightsSheet.show(
                        context,
                        bookId: widget.handle.manifest.id,
                        groupId: widget.groupId,
                        onJumpToPage: cubit.goToPage,
                      ),
                    ),
                  ),
                  AppFadeOverlay.bottom(color: colors.paper, height: 135),

                  ReaderChromeSlot(
                    alignment: Alignment.bottomCenter,
                    visible: _chromeVisible,
                    fromTop: false,
                    child:
                        BlocBuilder<ReadingProgressCubit, ReadingProgressState>(
                          builder: (context, progressState) => ReaderFooter(
                            progress: progressState.fraction,
                            currentPage: index,
                            totalPages: total,
                          ),
                        ),
                  ),
                  ReaderPullIndicator(pull: _pull),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 96,
                    child: SafeArea(
                      top: false,
                      child: Center(
                        child:
                            BlocConsumer<
                              ReadingProgressCubit,
                              ReadingProgressState
                            >(
                              listenWhen: (previous, current) =>
                                  !previous.bookCompleted &&
                                  current.bookCompleted &&
                                  previous.fraction >= markCompleteThreshold,
                              listener: (context, progressState) {
                                AppToast.show(
                                  context,
                                  message:
                                      "🎉 Nice work — you finished ${widget.handle.manifest.title}!",
                                  type: AppToastType.success,
                                );
                              },
                              builder: (context, progressState) {
                                final showPill =
                                    !progressState.bookCompleted &&
                                    progressState.fraction >=
                                        markCompleteThreshold &&
                                    progressState.fraction < 1.0;
                                return ReaderMarkCompletePill(
                                  visible: showPill,
                                  onComplete: context
                                      .read<ReadingProgressCubit>()
                                      .markComplete,
                                );
                              },
                            ),
                      ),
                    ),
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
