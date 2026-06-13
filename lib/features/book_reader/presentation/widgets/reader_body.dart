import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:zapbook/zbf/zbf.dart';

import 'package:zapbook/core/data/paragraph_merger.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_block_view.dart';
import 'package:zapbook/theme/reading_style.dart';

enum ReaderPullEdge { top, bottom }

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
    required this.style,
    required this.asset,
    required this.canGoForward,
    required this.canGoBack,
    required this.onTurnForward,
    required this.onTurnBackward,
    required this.onTap,
    required this.onUserScrollDirection,
    required this.onPullChanged,
    this.highlightQuery,
    this.onHighlightComplete,
    super.key,
  });

  final List<BookBlock> blocks;
  final ReadingStyle style;
  final Uint8List? Function(String assetRef) asset;
  final bool canGoForward;
  final bool canGoBack;
  final VoidCallback onTurnForward;
  final VoidCallback onTurnBackward;
  final VoidCallback onTap;

  final ValueChanged<ScrollDirection> onUserScrollDirection;
  final ValueChanged<ReaderPullState?> onPullChanged;
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

  late final List<BookBlock> _merged = mergeReadingBlocks(widget.blocks);

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
    _tapTimer?.cancel();
    super.dispose();
  }

  bool _allowedAt(ReaderPullEdge edge) =>
      edge == ReaderPullEdge.bottom ? widget.canGoForward : widget.canGoBack;

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
        if (armedEdge == ReaderPullEdge.bottom) {
          widget.onTurnForward();
        } else {
          widget.onTurnBackward();
        }
      });
    }
    _clearPull();
  }

  Widget _column(String? query, double? progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final block in _merged)
          ReaderBlockView(
            block: block,
            style: widget.style,
            asset: widget.asset,
            highlightQuery: query,
            highlightProgress: progress,
          ),
      ],
    );
  }

  Widget _buildBlocks(BuildContext context) {
    final query = widget.highlightQuery;
    if (query == null || query.isEmpty) {
      return _column(null, null);
    }
    return TweenAnimationBuilder<double>(
      key: ValueKey(query),
      tween: Tween(begin: 1.0, end: 0.0),
      duration: const Duration(milliseconds: 2600),
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      onEnd: widget.onHighlightComplete,
      builder: (context, t, _) =>
          _column(query, t),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onNotification,
        child: ScrollConfiguration(
          behavior: const _NoGlowScrollBehavior(),
          child: ListView(
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
                  child: SelectionArea(child: _buildBlocks(context)),
                ),
              ),
            ],
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
