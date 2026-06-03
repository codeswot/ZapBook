import 'package:equatable/equatable.dart';

import 'package:zapbook/features/library/domain/entities/ingestion_job.dart';
import 'package:zapbook/features/library/domain/enums/ingestion_job_status.dart';

final class IngestionQueueState extends Equatable {
  const IngestionQueueState({this.jobs = const []});

  final List<IngestionJob> jobs;

  Iterable<IngestionJob> get active => jobs.where(
    (job) =>
        job.status == IngestionJobStatus.queued ||
        job.status == IngestionJobStatus.running,
  );

  List<IngestionJob> get visibleJobs => jobs
      .where((job) => job.status != IngestionJobStatus.success)
      .toList(growable: false);

  int get runningCount =>
      jobs.where((job) => job.status == IngestionJobStatus.running).length;

  bool get isIdle => active.isEmpty;

  IngestionQueueState upsert(IngestionJob job) {
    final index = jobs.indexWhere((existing) => existing.id == job.id);
    final next = [...jobs];
    if (index >= 0) {
      next[index] = job;
    } else {
      next.add(job);
    }
    return IngestionQueueState(jobs: next);
  }

  IngestionQueueState patch(
    String id,
    IngestionJob Function(IngestionJob job) update,
  ) {
    final index = jobs.indexWhere((job) => job.id == id);
    if (index < 0) {
      return this;
    }
    final next = [...jobs];
    next[index] = update(next[index]);
    return IngestionQueueState(jobs: next);
  }

  @override
  List<Object?> get props => [jobs];
}
