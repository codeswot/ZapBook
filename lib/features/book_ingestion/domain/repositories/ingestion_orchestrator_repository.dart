abstract class IngestionOrchestratorRepository {
  Future<String> createCircleBook({
    required String circleDirId,
    required String humanTitle,
    required Map<String, dynamic> metadata,
  });

  Future<void> deleteBookFiles(String circleDirId);

  Future<void> finalizeAndUploadBook({
    required String circleDirId,
    required String marmotGroupId,
  });
}
