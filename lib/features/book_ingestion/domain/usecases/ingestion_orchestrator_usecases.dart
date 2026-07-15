import 'package:injectable/injectable.dart';
import 'package:zapbook/features/book_ingestion/domain/repositories/ingestion_orchestrator_repository.dart';

@injectable
class CreateCircleBookUseCase {
  const CreateCircleBookUseCase(this._repository);

  final IngestionOrchestratorRepository _repository;

  Future<String> call({
    required String circleDirId,
    required String humanTitle,
    required Map<String, dynamic> metadata,
  }) {
    return _repository.createCircleBook(
      circleDirId: circleDirId,
      humanTitle: humanTitle,
      metadata: metadata,
    );
  }
}

@injectable
class DeleteBookFilesUseCase {
  const DeleteBookFilesUseCase(this._repository);

  final IngestionOrchestratorRepository _repository;

  Future<void> call(String circleDirId) {
    return _repository.deleteBookFiles(circleDirId);
  }
}

@injectable
class FinalizeAndUploadBookUseCase {
  const FinalizeAndUploadBookUseCase(this._repository);

  final IngestionOrchestratorRepository _repository;

  Future<void> call({
    required String circleDirId,
    required String marmotGroupId,
  }) {
    return _repository.finalizeAndUploadBook(
      circleDirId: circleDirId,
      marmotGroupId: marmotGroupId,
    );
  }
}
