import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/domain/ingestion_stage.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/ingestion_orchestrator_cubit.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/core/presentation/widgets/bouncing_interactive_widget.dart';

class LibraryProcessingTile extends StatefulWidget {
  const LibraryProcessingTile({
    super.key,
    required this.circleBookId,
    required this.task,
  });

  final String circleBookId;
  final IngestionTaskState task;

  @override
  State<LibraryProcessingTile> createState() => _LibraryProcessingTileState();
}

class _LibraryProcessingTileState extends State<LibraryProcessingTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final task = widget.task;
    final failed = task.progress.stage == IngestionStage.error;

    return BouncingInteractiveWidget(
      onTap: failed
          ? () => context.read<IngestionOrchestratorCubit>().cancelIngestion(
              widget.circleBookId,
            )
          : null,
      child: AspectRatio(
        aspectRatio: 0.727,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: failed ? colors.tomatoTint : colors.mist,
            borderRadius: AppRadii.br12,
            border: Border.all(
              color: failed ? colors.tomato : colors.hairline2,
            ),
            image: task.wizardData?.coverImage != null
                ? DecorationImage(
                    image: MemoryImage(task.wizardData!.coverImage!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.6),
                      BlendMode.darken,
                    ),
                  )
                : null,
          ),
          child: failed
              ? _FailedContent(colors: colors, task: task)
              : _RunningContent(colors: colors, task: task, pulse: _pulse),
        ),
      ),
    );
  }
}

class _RunningContent extends StatelessWidget {
  final SemanticColors colors;
  final IngestionTaskState task;
  final AnimationController pulse;

  const _RunningContent({
    required this.colors,
    required this.task,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeTransition(
          opacity: Tween<double>(begin: 0.45, end: 1).animate(pulse),
          child: Icon(LucideIcons.sparkles, size: 16, color: colors.bitcoin),
        ),
        const Spacer(),
        Text(
          task.wizardData?.title ??
              task.file.path.split(Platform.pathSeparator).last,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.typography.caption.copyWith(
            color: task.wizardData?.coverImage != null
                ? Colors.white
                : colors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _stageLabel(task.progress.stage),
          style: context.typography.caption.copyWith(color: colors.slate),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: task.progress.progress,
          color: colors.bitcoin,
        ),
      ],
    );
  }
}

class _FailedContent extends StatelessWidget {
  final SemanticColors colors;
  final IngestionTaskState task;

  const _FailedContent({required this.colors, required this.task});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(LucideIcons.triangleAlert, size: 16, color: colors.tomato),
        const Spacer(),
        Text(
          task.wizardData?.title ??
              task.file.path.split(Platform.pathSeparator).last,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.typography.caption.copyWith(
            color: task.wizardData?.coverImage != null
                ? Colors.white
                : colors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          task.progress.error ?? 'Unknown Error',
          maxLines: 2,
          style: context.typography.caption.copyWith(color: colors.tomato),
        ),
      ],
    );
  }
}

String _stageLabel(IngestionStage stage) => switch (stage) {
  IngestionStage.fileSelected => 'Reading file',
  IngestionStage.extracting => 'Extracting',
  IngestionStage.assembling => 'Assembling',
  IngestionStage.writing => 'Saving',
  IngestionStage.needsAiProcessing => 'Saved',
  IngestionStage.complete => 'Done',
  IngestionStage.error => 'Error',
};
