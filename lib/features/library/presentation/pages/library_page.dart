import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zapbook/core/domain/wizard_data.dart';
import 'package:zapbook/features/library/presentation/widgets/book_wizard_sheet.dart';
import 'package:zapbook/features/library/presentation/bloc/ingestion_queue_cubit.dart';
import 'package:zapbook/features/library/presentation/widgets/library_body.dart';
import 'package:zapbook/features/library/presentation/widgets/library_header.dart';
import 'package:zapbook/features/library/presentation/bloc/page/ingestion_page_cubit.dart';
import 'package:zapbook/features/library/presentation/bloc/page/ingestion_page_state.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_toast.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LibraryView();
  }
}

class _LibraryView extends StatelessWidget {
  const _LibraryView();

  Future<void> _onPageCubitState(
    BuildContext context,
    IngestionPageState state,
  ) async {
    if (state is IngestionPageError) {
      context.toast.showError(state.message);
      return;
    }
    if (state is! IngestionPageFilePicked) {
      return;
    }

    final queue = context.read<IngestionQueueCubit>();
    final duplicate = await queue.findDuplicate(state.file);
    if (!context.mounted) {
      return;
    }
    if (duplicate.existing != null) {
      context.toast.showInfo(
        '“${duplicate.existing!.title}” is already in your library',
      );
      return;
    }

    final completer = Completer<WizardData>();
    queue.enqueue(
      state.file,
      wizardDataFuture: completer.future,
      contentHash: duplicate.hash,
    );
    BookWizardSheet.show(
      context,
      completer: completer,
      rawTitle: state.rawTitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<IngestionPageCubit, IngestionPageState>(
      listenWhen: (_, curr) =>
          curr is IngestionPageFilePicked || curr is IngestionPageError,
      listener: _onPageCubitState,
      child: Scaffold(
        backgroundColor: context.colors.paper,
        body: SafeArea(
          child: Column(
            children: const [
              LibraryHeader(),
              Expanded(child: LibraryBody()),
            ],
          ),
        ),
      ),
    );
  }
}
