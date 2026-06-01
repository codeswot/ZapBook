import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/zbf/zbf.dart';

import 'package:zapbook/features/book_ingestion/data/support/paragraph_merger.dart';
import 'package:zapbook/features/book_ingestion/presentation/widgets/reader/reader_block_view.dart';
import 'package:zapbook/features/book_ingestion/presentation/widgets/reader/reading_style.dart';

enum _Edge { top, bottom }

/// The scrollable text of a single page, with friction-based page turns.
///
/// You can only advance once you have scrolled to the bottom edge; from there
/// an extra "pull" past a threshold arms a turn (light haptic + "release to
/// turn" indicator), and releasing fires the turn. Pulling at the top edge
/// turns back. Below the threshold the overscroll springs back and nothing
/// happens — so normal reading scrolls never accidentally flip the page.
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

  @override
  State<ReaderBody> createState() => _ReaderBodyState();
}

class _ReaderBodyState extends State<ReaderBody> {
  static const double _armThreshold = 110;

  double _overscroll = 0;
  _Edge? _edge;
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

  bool _allowedAt(_Edge edge) =>
      edge == _Edge.bottom ? widget.canGoForward : widget.canGoBack;

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
      if (_edge != null || _armed || _overscroll != 0) {
        setState(() {
          _overscroll = 0;
          _armed = false;
          _edge = null;
        });
      }
      return false;
    }

    final edge = overflow > 0 ? _Edge.bottom : _Edge.top;
    if (!_allowedAt(edge)) return false;

    final distance = overflow.abs();
    final wasArmed = _armed;
    setState(() {
      _edge = edge;
      _overscroll = distance;
      _armed = distance >= _armThreshold;
    });
    if (_armed && !wasArmed) {
      HapticFeedback.lightImpact();
    }
    return false;
  }

  void _release() {
    final armedEdge = _armed ? _edge : null;
    if (armedEdge != null) {
      HapticFeedback.lightImpact();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (armedEdge == _Edge.bottom) {
          widget.onTurnForward();
        } else {
          widget.onTurnBackward();
        }
      });
    }
    if (_overscroll != 0 || _armed || _edge != null) {
      setState(() {
        _overscroll = 0;
        _armed = false;
        _edge = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(
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
                      child: SelectionArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final block in _merged)
                              ReaderBlockView(
                                block: block,
                                style: widget.style,
                                asset: widget.asset,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_edge == _Edge.top)
            _TurnIndicator(
              alignment: Alignment.topCenter,
              armed: _armed,
              progress: (_overscroll / _armThreshold).clamp(0, 1),
              label: _armed ? 'Release for previous' : 'Pull for previous',
              icon: Icons.keyboard_arrow_up_rounded,
              color: colors.ink,
              background: colors.paper,
            ),
          if (_edge == _Edge.bottom)
            _TurnIndicator(
              alignment: Alignment.bottomCenter,
              armed: _armed,
              progress: (_overscroll / _armThreshold).clamp(0, 1),
              label: _armed ? 'Release for next' : 'Pull for next',
              icon: Icons.keyboard_arrow_down_rounded,
              color: colors.ink,
              background: colors.paper,
            ),
        ],
      ),
    );
  }
}

class _TurnIndicator extends StatelessWidget {
  const _TurnIndicator({
    required this.alignment,
    required this.armed,
    required this.progress,
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
  });

  final Alignment alignment;
  final bool armed;
  final double progress;
  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final top = alignment == Alignment.topCenter;
    return Align(
      alignment: alignment,
      child: Padding(
        padding: EdgeInsets.only(
          top: top ? MediaQuery.of(context).padding.top + 20 : 0,
          bottom: top ? 0 : MediaQuery.of(context).padding.bottom + 24,
        ),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: 0.85 + (progress * 0.15),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 120),
            opacity: (0.3 + progress * 0.7).clamp(0.0, 1.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: color.withValues(alpha: armed ? 1 : 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 150),
                    turns: armed ? 0.5 : 0,
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: context.typography.caption.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
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
