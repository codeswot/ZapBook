import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/domain/entities/book_search_hit.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/core/presentation/widgets/app_input.dart';
import 'package:zapbook/core/presentation/widgets/app_shimmer.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/reader_search_cubit.dart';

class ReaderSearchSheet extends StatefulWidget {
  const ReaderSearchSheet({
    required this.circleDirId,
    required this.onSelect,
    super.key,
  });

  final String circleDirId;
  final void Function(int page, String query) onSelect;

  static Future<void> show(
    BuildContext context, {
    required String circleDirId,
    required void Function(int page, String query) onSelect,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: context.colors.transparent,
      builder: (_) => BlocProvider<ReaderSearchCubit>(
        create: (_) => getIt<ReaderSearchCubit>(),
        child: ReaderSearchSheet(circleDirId: circleDirId, onSelect: onSelect),
      ),
    );
  }

  @override
  State<ReaderSearchSheet> createState() => _ReaderSearchSheetState();
}

class _ReaderSearchSheetState extends State<ReaderSearchSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final bottomInset = mediaQuery.viewInsets.bottom;
    final bottomPadding = mediaQuery.padding.bottom;
    final sheetHeight = screenHeight - 150;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: BorderRadius.circular(32),
        border: Border(top: BorderSide(color: colors.hairline)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPadding + bottomInset),
      margin: const EdgeInsets.all(6).copyWith(bottom: 4 + bottomPadding),
      child: BlocBuilder<ReaderSearchCubit, ReaderSearchState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: colors.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('Search this book', style: typography.h3),
              ),
              AppInput(
                controller: _controller,
                autofocus: true,
                icon: LucideIcons.search,
                hintText: 'Find a word or phrase…',
                onChanged: (raw) => context.read<ReaderSearchCubit>().query(
                  widget.circleDirId,
                  raw,
                ),
              ),
              if (!state.semanticAvailable)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'AI search unavailable — showing exact matches only',
                    style: typography.caption.copyWith(color: colors.slate),
                  ),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: _ResultsList(
                  loading: state.loading,
                  query: state.query,
                  hits: state.hits,
                  onSelect: (hit) {
                    context.pop();
                    widget.onSelect(hit.pageNumber - 1, state.query);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({
    required this.loading,
    required this.query,
    required this.hits,
    required this.onSelect,
  });

  final bool loading;
  final String query;
  final List<BookSearchHit> hits;
  final ValueChanged<BookSearchHit> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    if (loading && hits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: AppShimmer(
          child: Column(
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppShimmerBox(width: 60, height: 12),
                      const SizedBox(height: 6),
                      const AppShimmerBox(width: double.infinity, height: 14),
                      const SizedBox(height: 4),
                      AppShimmerBox(
                        width: (i == 0
                            ? 180.0
                            : i == 1
                            ? 120.0
                            : 220.0),
                        height: 14,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }
    if (query.length >= 3 && hits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text(
          'No matches in this book',
          textAlign: TextAlign.center,
          style: typography.body.copyWith(color: colors.slate),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: hits.length,
      itemBuilder: (context, i) {
        final hit = hits[i];
        return InkWell(
          onTap: () => onSelect(hit),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Page ${hit.pageNumber}',
                  style: typography.bodyS.copyWith(
                    color: colors.bitcoin,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  _snippetSpan(hit.snippet, typography, colors),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  TextSpan _snippetSpan(
    String snippet,
    AppTypography typography,
    SemanticColors colors,
  ) {
    final base = typography.caption.copyWith(color: colors.slate);
    final strong = typography.caption.copyWith(
      color: colors.ink,
      fontWeight: FontWeight.w800,
    );
    final parts = snippet.split(BookSearchHit.highlightStart);
    final spans = <TextSpan>[TextSpan(text: parts.first, style: base)];
    for (final part in parts.skip(1)) {
      final end = part.indexOf(BookSearchHit.highlightEnd);
      if (end == -1) {
        spans.add(TextSpan(text: part, style: base));
        continue;
      }
      spans.add(TextSpan(text: part.substring(0, end), style: strong));
      spans.add(TextSpan(text: part.substring(end + 1), style: base));
    }
    return TextSpan(children: spans, style: base);
  }
}
