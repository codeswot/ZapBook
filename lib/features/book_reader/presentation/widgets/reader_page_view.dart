import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zapbook/zbf/zbf.dart';

import 'package:zapbook/core/presentation/bloc/performance/performance_cubit.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/viewer/zbf_viewer_state.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_body.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_loading.dart';
import 'package:zapbook/theme/reading_style.dart';

class ReaderPageView extends StatelessWidget {
  const ReaderPageView({
    required this.state,
    required this.blocks,
    required this.page,
    required this.index,
    required this.total,
    required this.style,
    required this.turningForward,
    required this.asset,
    required this.initialScrollOffset,
    required this.highlightQuery,
    required this.onTapChrome,
    required this.onRetry,
    required this.onSkip,
    required this.onScrollDelta,
    required this.onScrollOffsetChanged,
    required this.onUserScrollDirection,
    required this.onTurnForward,
    required this.onTurnBackward,
    required this.onPullChanged,
    required this.onHighlightComplete,
    super.key,
  });

  final ZbfViewerState state;
  final List<BookBlock>? blocks;
  final BookPage page;
  final int index;
  final int total;
  final ReadingStyle style;
  final bool turningForward;
  final Future<Uint8List?> Function(String assetRef) asset;
  final double? initialScrollOffset;
  final String? highlightQuery;
  final VoidCallback onTapChrome;
  final VoidCallback onRetry;
  final VoidCallback? onSkip;
  final ValueChanged<double> onScrollDelta;
  final ValueChanged<double> onScrollOffsetChanged;
  final ValueChanged<ScrollDirection> onUserScrollDirection;
  final VoidCallback onTurnForward;
  final VoidCallback onTurnBackward;
  final ValueChanged<ReaderPullState?> onPullChanged;
  final VoidCallback onHighlightComplete;

  Widget _tappable(Widget child) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTapChrome,
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final reduceEffects = context.watch<PerformanceCubit>().state.reduceEffects;
    return AnimatedSwitcher(
      duration: reduceEffects
          ? Duration.zero
          : const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final isIncoming = child.key == ValueKey<int>(index);
        final beginOffset = turningForward
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
      child: KeyedSubtree(key: ValueKey<int>(index), child: _content()),
    );
  }

  Widget _content() {
    if (blocks == null) {
      return _tappable(
        state.failedPages.contains(index)
            ? ReaderPagePrepFailed(
                key: ValueKey<String>('failed_$index'),
                pageNumber: index + 1,
                onRetry: onRetry,
                onSkip: onSkip,
              )
            : ReaderPageLoading(
                key: ValueKey<String>('loading_$index'),
                message: 'Preparing page ${index + 1}…',
              ),
      );
    }

    final rasterizing =
        state.rasterizingPages.contains(index) &&
        page.layoutType == BookLayoutType.illustration &&
        !state.imagePages.containsKey(index);
    if (rasterizing) {
      return _tappable(
        ReaderPageLoading(
          key: ValueKey<String>('raster_$index'),
          message: 'Rendering page ${index + 1}…',
        ),
      );
    }

    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (n) {
        onScrollDelta(n.scrollDelta?.abs() ?? 0);
        return false;
      },
      child: ReaderBody(
        blocks: blocks!,
        style: style,
        asset: asset,
        canGoForward: index < total - 1,
        canGoBack: index > 0,
        initialScrollOffset: initialScrollOffset,
        onScrollOffsetChanged: onScrollOffsetChanged,
        onTap: onTapChrome,
        onUserScrollDirection: onUserScrollDirection,
        onTurnForward: onTurnForward,
        onTurnBackward: onTurnBackward,
        onPullChanged: onPullChanged,
        highlightQuery: highlightQuery,
        onHighlightComplete: onHighlightComplete,
      ),
    );
  }
}
