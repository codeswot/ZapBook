import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/core/presentation/widgets/app_button.dart';
import 'package:zapbook/core/presentation/widgets/app_input.dart';
import 'package:zapbook/core/presentation/widgets/app_sheet.dart';
import 'package:zapbook/core/presentation/widgets/app_toast.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/highlights/highlights_cubit.dart';

class AddNoteSheet extends StatefulWidget {
  const AddNoteSheet({
    super.key,
    required this.highlightId,
    required this.highlightsCubit,
  });

  final String highlightId;
  final HighlightsCubit highlightsCubit;

  static Future<void> show(
    BuildContext context, {
    required String highlightId,
    required HighlightsCubit highlightsCubit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: context.colors.transparent,
      builder: (_) => AddNoteSheet(
        highlightId: highlightId,
        highlightsCubit: highlightsCubit,
      ),
    );
  }

  @override
  State<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<AddNoteSheet> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final note = _controller.text.trim();
    if (note.isEmpty) return;

    setState(() => _saving = true);
    await widget.highlightsCubit.addNote(widget.highlightId, note);
    if (mounted) {
      Navigator.of(context).pop();
      context.toast.showSuccess('Note saved', rootNavigator: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return AppSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Add a note',
            style: typography.displayM.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Attach your thoughts to this highlight.',
            style: typography.body.copyWith(color: colors.slate),
          ),
          const SizedBox(height: 18),
          AppInput(
            controller: _controller,
            icon: LucideIcons.notebookPen,
            label: 'Note',
            hintText: 'What stood out to you?',
          ),
          const SizedBox(height: 18),
          AppButton(
            label: _saving ? 'Saving…' : 'Save note',
            fullWidth: true,
            variant: AppButtonVariant.purple,
            isLoading: _saving,
            onTap: _saving ? null : _save,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
