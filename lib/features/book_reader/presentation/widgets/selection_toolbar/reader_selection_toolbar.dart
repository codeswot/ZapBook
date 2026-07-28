import 'package:flutter/material.dart';

import 'package:zapbook/core/data/paragraph_merger.dart';
import 'package:zapbook/core/presentation/widgets/app_toast.dart';
import 'package:zapbook/features/book_reader/domain/anchor_resolution.dart';
import 'package:zapbook/features/book_reader/domain/entities/highlight.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/highlights/highlights_cubit.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/add_note_sheet.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/highlight_zap_picker_sheet.dart';

class ReaderSelectionToolbar extends StatelessWidget {
  const ReaderSelectionToolbar({
    super.key,
    required this.selectableRegionState,
    required this.selectedText,
    required this.mergedBlockTexts,
    required this.pageRuns,
    this.disambiguationHint,
    required this.groupId,
    required this.bookTitle,
    required this.highlightsCubit,
  });

  final SelectableRegionState selectableRegionState;
  final String selectedText;
  final List<String> mergedBlockTexts;
  final List<BlockProvenanceRun> pageRuns;
  final int? disambiguationHint;
  final String groupId;
  final String bookTitle;
  final HighlightsCubit highlightsCubit;

  Future<void> _highlight(
    BuildContext context,
    List<HighlightSpan> spans,
  ) async {
    selectableRegionState.hideToolbar();
    final highlight = await highlightsCubit.highlight(
      spans: spans,
      quoteSnapshot: selectedText,
    );
    if (highlight != null && context.mounted) {
      context.toast.showSuccess('Highlighted', rootNavigator: true);
    }
  }

  Future<void> _addNote(BuildContext context, List<HighlightSpan> spans) async {
    selectableRegionState.hideToolbar();
    final highlight = await highlightsCubit.highlight(
      spans: spans,
      quoteSnapshot: selectedText,
    );
    if (highlight != null && context.mounted) {
      AddNoteSheet.show(
        context,
        highlightId: highlight.id,
        highlightsCubit: highlightsCubit,
      );
    }
  }

  void _zap(BuildContext context) {
    selectableRegionState.hideToolbar();
    HighlightZapPickerSheet.show(
      context,
      groupId: groupId,
      bookTitle: bookTitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final spans = resolveSelectionAnchor(
      mergedBlockTexts: mergedBlockTexts,
      pageRuns: pageRuns,
      selectedText: selectedText,
      disambiguationHint: disambiguationHint,
    );

    final items = <ContextMenuButtonItem>[
      if (spans != null)
        ContextMenuButtonItem(
          label: 'Highlight',
          onPressed: () => _highlight(context, spans),
        ),
      if (spans != null)
        ContextMenuButtonItem(
          label: 'Note',
          onPressed: () => _addNote(context, spans),
        ),
      if (spans != null && groupId.isNotEmpty)
        ContextMenuButtonItem(label: 'Zap', onPressed: () => _zap(context)),
      ...selectableRegionState.contextMenuButtonItems,
    ];

    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: selectableRegionState.contextMenuAnchors,
      buttonItems: items,
    );
  }
}
