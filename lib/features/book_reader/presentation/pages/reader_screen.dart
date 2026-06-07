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
import 'package:zapbook/core/domain/book_segment_source.dart';
import 'package:zapbook/core/domain/pdf_page_rasterizer.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/reader_settings/reader_settings_cubit.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/viewer/zbf_viewer_cubit.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/viewer/zbf_viewer_state.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_body.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_footer.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_header.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_pull_indicator.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_toc_sheet.dart';
import 'package:zapbook/theme/reading_style.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    required this.handle,
    this.rasterizer,
    this.segmentLoader,
    this.onExit,
    super.key,
  });

  final ZbfBookHandle handle;
  final PdfPageRasterizer? rasterizer;
  final BookSegmentLoader? segmentLoader;
  final VoidCallback? onExit;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  bool _chromeVisible = false;
  bool _turningForward = true;
  ReaderPullState? _pull;

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
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ZbfViewerCubit(
            handle: widget.handle,
            rasterizer: widget.rasterizer,
            segmentLoader: widget.segmentLoader,
          ),
        ),
        BlocProvider.value(value: getIt<ReaderSettingsCubit>()),
      ],
      child: Scaffold(
        backgroundColor: colors.paper,
        body: BlocBuilder<ZbfViewerCubit, ZbfViewerState>(
          builder: (context, state) {
            final cubit = context.read<ZbfViewerCubit>();
            final total = widget.handle.manifest.pageCount;
            final index = state.currentPage;
            final font = context.select<ReaderSettingsCubit, ReaderFont>(
              (c) => c.state.font,
            );
            final style = ReadingStyle.of(font, colors);
            final blocks = _blocksFor(index, state);
            final page = widget.handle.pageAt(index);

            return Stack(
              children: [
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
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
                          ? ReaderPageLoading(
                              key: ValueKey<String>('loading_$index'),
                              message: 'Preparing page ${index + 1}…',
                            )
                          : (state.rasterizingPages.contains(index) &&
                                page.layoutType ==
                                    BookLayoutType.illustration &&
                                !state.imagePages.containsKey(index))
                          ? ReaderPageLoading(
                              key: ValueKey<String>('raster_$index'),
                              message: 'Rendering page ${index + 1}…',
                            )
                          : ReaderBody(
                              blocks: blocks,
                              style: style,
                              asset: widget.handle.asset,
                              canGoForward: index < total - 1,
                              canGoBack: index > 0,
                              onTap: _toggleChrome,
                              onUserScrollDirection: _onScrollDirection,
                              onTurnForward: () {
                                _turningForward = true;
                                cubit.nextPage();
                              },
                              onTurnBackward: () {
                                _turningForward = false;
                                cubit.previousPage();
                              },
                              onPullChanged: _onPullChanged,
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
                  child: ReaderFooter(
                    progress: total == 0 ? 0 : (index + 1) / total,
                    currentPage: index,
                    totalPages: total,
                  ),
                ),
                ReaderPullIndicator(pull: _pull),
              ],
            );
          },
        ),
      ),
    );
  }
}
