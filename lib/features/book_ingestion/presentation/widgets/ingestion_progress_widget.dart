import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_progress.dart';

import 'package:zapbook/features/book_ingestion/domain/enums/ingestion_stage.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/ingestion_bloc.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/ingestion_state.dart';

class IngestionProgressWidget extends StatelessWidget {
  const IngestionProgressWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IngestionBloc, IngestionState>(
      builder: (context, state) => switch (state) {
        IngestionIdle() => const _IngestionIdleView(),
        IngestionInProgress() => _IngestionRunningView(state: state),
        IngestionNeedsAiProcessing() => _IngestionNeedsAiView(state: state),
        IngestionComplete() => _IngestionCompleteView(state: state),
        IngestionFailed() => _IngestionFailedView(state: state),
      },
    );
  }
}

class _IngestionIdleView extends StatelessWidget {
  const _IngestionIdleView();

  @override
  Widget build(BuildContext context) {
    return Text('Select a book to ingest', style: context.typography.body);
  }
}

class _IngestionRunningView extends StatelessWidget {
  const _IngestionRunningView({required this.state});

  final IngestionInProgress state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_stageLabel(state.stage), style: context.typography.label),
        const SizedBox(height: 8),
        AppProgress(value: state.progress),
        const SizedBox(height: 8),
        Text(state.currentItem, style: context.typography.bodyS),
      ],
    );
  }
}

class _IngestionNeedsAiView extends StatelessWidget {
  const _IngestionNeedsAiView({required this.state});

  final IngestionNeedsAiProcessing state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Saved — needs AI processing', style: context.typography.label),
        const SizedBox(height: 8),
        Text(
          '${state.pagesNeedingProcessing} pages flagged for Part 1B',
          style: context.typography.bodyS,
        ),
      ],
    );
  }
}

class _IngestionCompleteView extends StatelessWidget {
  const _IngestionCompleteView({required this.state});

  final IngestionComplete state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Saved “${state.manifest.title}”',
          style: context.typography.label,
        ),
        const SizedBox(height: 8),
        Text(
          '${state.manifest.chapterCount} chapters · '
          '${state.manifest.pageCount} pages',
          style: context.typography.bodyS,
        ),
      ],
    );
  }
}

class _IngestionFailedView extends StatelessWidget {
  const _IngestionFailedView({required this.state});

  final IngestionFailed state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Failed during ${_stageLabel(state.failedAt)}',
          style: context.typography.label.copyWith(
            color: context.colors.tomato,
          ),
        ),
        const SizedBox(height: 8),
        Text(state.error, style: context.typography.bodyS),
      ],
    );
  }
}

String _stageLabel(IngestionStage stage) => switch (stage) {
  IngestionStage.fileSelected => 'Reading file',
  IngestionStage.extracting => 'Extracting content',
  IngestionStage.assembling => 'Assembling book',
  IngestionStage.writing => 'Writing ZBF',
  IngestionStage.needsAiProcessing => 'Needs AI processing',
  IngestionStage.complete => 'Complete',
  IngestionStage.error => 'Error',
};
