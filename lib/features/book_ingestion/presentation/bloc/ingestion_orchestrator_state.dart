part of 'ingestion_orchestrator_cubit.dart';

class IngestionTaskState {
  const IngestionTaskState({
    required this.file,
    required this.progress,
    this.isGroupCreated = false,
    this.isExtractComplete = false,
    this.marmotGroupId,
  });

  final File file;
  final IngestionProgress progress;
  final bool isGroupCreated;
  final bool isExtractComplete;
  final String? marmotGroupId;

  IngestionTaskState copyWith({
    File? file,
    IngestionProgress? progress,
    bool? isGroupCreated,
    bool? isExtractComplete,
    String? marmotGroupId,
  }) {
    return IngestionTaskState(
      file: file ?? this.file,
      progress: progress ?? this.progress,
      isGroupCreated: isGroupCreated ?? this.isGroupCreated,
      isExtractComplete: isExtractComplete ?? this.isExtractComplete,
      marmotGroupId: marmotGroupId ?? this.marmotGroupId,
    );
  }
}

class IngestionOrchestratorState {
  const IngestionOrchestratorState({this.tasks = const {}});

  final Map<String, IngestionTaskState> tasks;

  IngestionOrchestratorState copyWith({
    Map<String, IngestionTaskState>? tasks,
  }) {
    return IngestionOrchestratorState(tasks: tasks ?? this.tasks);
  }
}
