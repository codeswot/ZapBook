import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/domain/ingestion_stage.dart';
import 'package:zapbook/features/library/domain/entities/ingestion_job.dart';
import 'package:zapbook/features/library/domain/enums/ingestion_job_status.dart';
import 'package:zapbook/features/library/presentation/bloc/ingestion_queue_cubit.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class LibraryProcessingTile extends StatefulWidget {
  const LibraryProcessingTile({super.key, required this.job});

  final IngestionJob job;

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
    final job = widget.job;
    final failed = job.status == IngestionJobStatus.failed;

    return BouncingInteractiveWidget(
      onTap: failed
          ? () => context.read<IngestionQueueCubit>().dismiss(job.id)
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
          ),
          child: failed
              ? _FailedContent(colors: colors, job: job)
              : _RunningContent(colors: colors, job: job, pulse: _pulse),
        ),
      ),
    );
  }
}

class _RunningContent extends StatelessWidget {
  final SemanticColors colors;
  final IngestionJob job;
  final AnimationController pulse;

  const _RunningContent({
    required this.colors,
    required this.job,
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
          job.fileName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.typography.caption.copyWith(
            color: colors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _stageLabel(job.stage),
          style: context.typography.caption.copyWith(color: colors.slate),
        ),
        const SizedBox(height: 8),
        _Progress(
          value: job.progress,
          color: colors.bitcoin,
          track: colors.paper4,
        ),
      ],
    );
  }
}

class _FailedContent extends StatelessWidget {
  final SemanticColors colors;
  final IngestionJob job;

  const _FailedContent({required this.colors, required this.job});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(LucideIcons.triangleAlert, size: 16, color: colors.tomato),
        const Spacer(),
        Text(
          job.fileName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.typography.caption.copyWith(
            color: colors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Failed · tap to dismiss',
          style: context.typography.caption.copyWith(color: colors.tomato),
        ),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({
    required this.value,
    required this.color,
    required this.track,
  });

  final double value;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadii.br999,
      child: LinearProgressIndicator(
        value: value <= 0 ? null : value.clamp(0.0, 1.0),
        minHeight: 5,
        backgroundColor: track,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
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
