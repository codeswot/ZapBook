import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:zapbook/zbf/zbf.dart';

import 'package:zapbook/core/data/paragraph_merger.dart';
import 'package:zapbook/core/presentation/bloc/performance/performance_cubit.dart';
import 'package:zapbook/features/book_reader/domain/anchor_resolution.dart';
import 'package:zapbook/features/book_reader/domain/entities/highlight.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/highlights/highlights_cubit.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_block_view.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/selection_toolbar/reader_selection_toolbar.dart';
import 'package:zapbook/core/presentation/theme/reading_style.dart';

enum ReaderPullEdge { top, bottom, left, right }

class ReaderPullState {
  const ReaderPullState({
    required this.edge,
    required this.armed,
    required this.progress,
  });

  final ReaderPullEdge edge;
  final bool armed;
  final double progress;
}

class ReaderBody extends StatefulWidget {
  const ReaderBody({
    required this.blocks,
    required this.bookId,
    required this.pageNumber,
    required this.groupId,
    required this.bookTitle,
    required this.style,
    required this.scrollDirection,
    required this.asset,
    required this.canGoForward,
    required this.canGoBack,
    required this.onTurnForward,
    required this.onTurnBackward,
    required this.onTap,
    required this.onUserScrollDirection,
    required this.onPullChanged,
    required this.onScrollOffsetChanged,
    this.initialScrollOffset,
    this.highlightQuery,
    this.onHighlightComplete,
    super.key,
  });

  final List<BookBlock> blocks;
  final String bookId;
  final int pageNumber;
  final String groupId;
  final String bookTitle;
  final ReadingStyle style;
  final ReaderScrollDirection scrollDirection;
  final Future<Uint8List?> Function(String assetRef) asset;
  final bool canGoForward;
  final bool canGoBack;
  final VoidCallback onTurnForward;
  final VoidCallback onTurnBackward;
  final VoidCallback onTap;

  final ValueChanged<ScrollDirection> onUserScrollDirection;
  final ValueChanged<ReaderPullState?> onPullChanged;
  final double? initialScrollOffset;
  final ValueChanged<double> onScrollOffsetChanged;
  final String? highlightQuery;
  final VoidCallback? onHighlightComplete;

  @override
  State<ReaderBody> createState() => _ReaderBodyState();
}

class _ReaderBodyState extends State<ReaderBody> {
  static const double _armThreshold = 110;

  double _overscroll = 0;
  ReaderPullEdge? _edge;
  bool _armed = false;

  Offset? _pointerDownPosition;
  int? _pointerDownTime;
  Timer? _tapTimer;

  late final _scrollController = ScrollController();
  late final MergeResult _mergeResult = mergeReadingBlocksWithProvenance(
    widget.blocks,
  );
  List<BookBlock> get _merged => _mergeResult.blocks;
  final GlobalKey _anchorKey = GlobalKey();
  int _anchorIndex = -1;
  bool _initialOffsetApplied = false;
  SelectedContent? _selectedContent;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollChange);
    _anchorIndex = _findAnchor();
    if (_anchorIndex >= 0) {
      _scheduleScroll();
    } else {
      _applyInitialOffset();
    }
  }

  @override
  void didUpdateWidget(ReaderBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlightQuery == oldWidget.highlightQuery) return;
    final next = _findAnchor();
    if (next != _anchorIndex) {
      setState(() => _anchorIndex = next);
    }
    if (next >= 0) _scheduleScroll();
  }

  void _applyInitialOffset() {
    if (_initialOffsetApplied) return;
    final offset = widget.initialScrollOffset;
    if (offset == null || offset <= 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _initialOffsetApplied = true;
      final target = offset >= double.infinity
          ? _scrollController.position.maxScrollExtent
          : offset
                .clamp(0.0, _scrollController.position.maxScrollExtent)
                .toDouble();
      if (target > 0) _scrollController.jumpTo(target);
    });
  }

  void _onScrollChange() {
    if (!_scrollController.hasClients) return;
    widget.onScrollOffsetChanged(_scrollController.position.pixels);
  }

  void _scheduleScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 320), _scrollToAnchor);
    });
  }

  int _findAnchor() {
    final query = widget.highlightQuery?.toLowerCase();
    if (query == null || query.isEmpty) return -1;
    for (var i = 0; i < _merged.length; i++) {
      if (_blockText(_merged[i]).toLowerCase().contains(query)) return i;
    }
    return -1;
  }

  void _scrollToAnchor([int attempt = 0]) {
    if (!mounted) return;
    final context = _anchorKey.currentContext;
    if (context == null) {
      if (attempt < 5) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollToAnchor(attempt + 1),
        );
      }
      return;
    }
    Scrollable.ensureVisible(
      context,
      alignment: 0.12,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  static String _blockText(BookBlock block) => switch (block) {
    HeadingBlock(:final text) => text,
    ParagraphBlock(:final text) => text,
    PullquoteBlock(:final text) => text,
    CodeBlock(:final text) => text,
    CaptionBlock(:final text) => text,
    ImageBlock(:final altText) => altText,
    _ => '',
  };

  void _onPointerDown(PointerDownEvent event) {
    _pointerDownPosition = event.position;
    _pointerDownTime = event.timeStamp.inMilliseconds;
  }

  void _onPointerUp(PointerUpEvent event) {
    final down = _pointerDownPosition;
    final downTime = _pointerDownTime;
    _pointerDownPosition = null;
    _pointerDownTime = null;
    if (down == null || downTime == null) return;

    final movedFar = (event.position - down).distance > 12;
    final heldLong = event.timeStamp.inMilliseconds - downTime > 300;
    if (movedFar || heldLong) return;

    if (_tapTimer?.isActive ?? false) {
      _tapTimer!.cancel();
      _tapTimer = null;
      return;
    }
    _tapTimer = Timer(const Duration(milliseconds: 220), () {
      _tapTimer = null;
      widget.onTap();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tapTimer?.cancel();
    super.dispose();
  }

  bool _allowedAt(ReaderPullEdge edge) =>
      (edge == ReaderPullEdge.bottom || edge == ReaderPullEdge.right)
      ? widget.canGoForward
      : widget.canGoBack;

  void _emitPull() {
    final edge = _edge;
    widget.onPullChanged(
      edge == null
          ? null
          : ReaderPullState(
              edge: edge,
              armed: _armed,
              progress: (_overscroll / _armThreshold).clamp(0, 1),
            ),
    );
  }

  void _clearPull() {
    if (_edge == null && !_armed && _overscroll == 0) return;
    _overscroll = 0;
    _armed = false;
    _edge = null;
    _emitPull();
  }

  bool _onNotification(ScrollNotification notification) {
    if (notification is UserScrollNotification &&
        notification.direction != ScrollDirection.idle) {
      widget.onUserScrollDirection(notification.direction);
    }

    final metrics = notification.metrics;

    double overflow = 0;
    if (metrics.pixels > metrics.maxScrollExtent) {
      overflow = metrics.pixels - metrics.maxScrollExtent;
    } else if (metrics.pixels < metrics.minScrollExtent) {
      overflow = metrics.pixels - metrics.minScrollExtent;
    }

    final dragEnded =
        notification is ScrollEndNotification ||
        (notification is ScrollUpdateNotification &&
            notification.dragDetails == null);
    if (dragEnded) {
      _release();
      return false;
    }

    if (overflow == 0) {
      _clearPull();
      return false;
    }

    final edge = overflow > 0 ? ReaderPullEdge.bottom : ReaderPullEdge.top;
    if (widget.scrollDirection == ReaderScrollDirection.horizontal) {
      return false;
    }
    if (!_allowedAt(edge)) return false;

    final wasArmed = _armed;
    _edge = edge;
    _overscroll = overflow.abs();
    _armed = _overscroll >= _armThreshold;
    if (_armed && !wasArmed) {
      HapticFeedback.lightImpact();
    }
    _emitPull();
    return false;
  }

  void _release() {
    final armedEdge = _armed ? _edge : null;
    if (armedEdge != null) {
      HapticFeedback.lightImpact();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (armedEdge == ReaderPullEdge.bottom ||
            armedEdge == ReaderPullEdge.right) {
          widget.onTurnForward();
        } else {
          widget.onTurnBackward();
        }
      });
    }
    _clearPull();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (widget.scrollDirection != ReaderScrollDirection.horizontal) return;

    final dx = details.delta.dx;
    if (_edge == null) {
      if (dx < -1) {
        _edge = ReaderPullEdge.right;
      } else if (dx > 1) {
        _edge = ReaderPullEdge.left;
      } else {
        return;
      }
    }

    if (_edge != null && !_allowedAt(_edge!)) {
      _edge = null;
      return;
    }

    if (_edge == ReaderPullEdge.right) {
      _overscroll += -dx;
    } else if (_edge == ReaderPullEdge.left) {
      _overscroll += dx;
    }

    _overscroll = _overscroll.clamp(0, 500);

    final wasArmed = _armed;
    _armed = _overscroll >= _armThreshold;
    if (_armed && !wasArmed) {
      HapticFeedback.lightImpact();
    }
    _emitPull();
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (widget.scrollDirection != ReaderScrollDirection.horizontal) return;
    _release();
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    Logger('ReaderBody').fine('to participate in the gesture arena');
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      child: GestureDetector(
        onHorizontalDragStart: _onHorizontalDragStart,
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        child: NotificationListener<ScrollNotification>(
          onNotification: _onNotification,
          child: ScrollConfiguration(
            behavior: const _NoGlowScrollBehavior(),
            child: ListView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.of(context).padding.top + 72,
                24,
                MediaQuery.of(context).padding.bottom + 96,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: ReadingStyle.maxContentWidth,
                    ),
                    child: SelectionArea(
                      onSelectionChanged: (content) =>
                          setState(() => _selectedContent = content),
                      contextMenuBuilder: (menuContext, state) {
                        final content = _selectedContent;
                        if (content == null || content.plainText.isEmpty) {
                          return AdaptiveTextSelectionToolbar.buttonItems(
                            anchors: state.contextMenuAnchors,
                            buttonItems: state.contextMenuButtonItems,
                          );
                        }
                        return ReaderSelectionToolbar(
                          selectableRegionState: state,
                          selectedText: content.plainText,
                          mergedBlockTexts: _merged
                              .map(blockPlainText)
                              .toList(),
                          pageRuns: _mergeResult.provenance,
                          groupId: widget.groupId,
                          bookTitle: widget.bookTitle,
                          highlightsCubit: context.read<HighlightsCubit>(),
                        );
                      },
                      child: _HighlightableBlocks(
                        blocks: _merged,
                        provenance: _mergeResult.provenance,
                        style: widget.style,
                        asset: widget.asset,
                        highlightQuery: widget.highlightQuery,
                        onHighlightComplete: widget.onHighlightComplete,
                        anchorIndex: _anchorIndex,
                        anchorKey: _anchorKey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

class _HighlightableBlocks extends StatelessWidget {
  const _HighlightableBlocks({
    required this.blocks,
    required this.provenance,
    required this.style,
    required this.asset,
    required this.highlightQuery,
    required this.onHighlightComplete,
    required this.anchorIndex,
    required this.anchorKey,
  });

  final List<BookBlock> blocks;
  final List<BlockProvenanceRun> provenance;
  final ReadingStyle style;
  final Future<Uint8List?> Function(String assetRef) asset;
  final String? highlightQuery;
  final VoidCallback? onHighlightComplete;
  final int anchorIndex;
  final Key anchorKey;

  @override
  Widget build(BuildContext context) {
    final query = highlightQuery;
    if (query == null || query.isEmpty) {
      return _BlockColumn(
        blocks: blocks,
        provenance: provenance,
        style: style,
        asset: asset,
        anchorIndex: anchorIndex,
        anchorKey: anchorKey,
      );
    }
    final reduceEffects = context.watch<PerformanceCubit>().state.reduceEffects;
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(query),
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: reduceEffects ? 700 : 2800),
        curve: Curves.linear,
        onEnd: onHighlightComplete,
        builder: (context, t, _) => _BlockColumn(
          blocks: blocks,
          provenance: provenance,
          style: style,
          asset: asset,
          highlightQuery: query,
          highlightProgress: t,
          anchorIndex: anchorIndex,
          anchorKey: anchorKey,
        ),
      ),
    );
  }
}

class _BlockColumn extends StatelessWidget {
  const _BlockColumn({
    required this.blocks,
    required this.provenance,
    required this.style,
    required this.asset,
    required this.anchorIndex,
    required this.anchorKey,
    this.highlightQuery,
    this.highlightProgress,
  });

  final List<BookBlock> blocks;
  final List<BlockProvenanceRun> provenance;
  final ReadingStyle style;
  final Future<Uint8List?> Function(String) asset;
  final int anchorIndex;
  final Key anchorKey;
  final String? highlightQuery;
  final double? highlightProgress;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HighlightsCubit, HighlightsState>(
      builder: (context, state) {
        final highlights = state is HighlightsLoaded
            ? state.highlights
            : const <Highlight>[];
        final rangesByBlock = <int, List<TextRange>>{};
        for (final highlight in highlights) {
          final mapped = mapSpansToMergedRanges(
            spans: highlight.spans,
            pageRuns: provenance,
          );
          mapped.forEach((blockIndex, ranges) {
            rangesByBlock
                .putIfAbsent(blockIndex, () => [])
                .addAll(
                  ranges.map((r) => TextRange(start: r.start, end: r.end)),
                );
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < blocks.length; i++)
              ReaderBlockView(
                key: i == anchorIndex ? anchorKey : null,
                block: blocks[i],
                style: style,
                asset: asset,
                highlightQuery: highlightQuery,
                highlightProgress: highlightProgress,
                persistedHighlightRanges: rangesByBlock[i],
              ),
          ],
        );
      },
    );
  }
}
