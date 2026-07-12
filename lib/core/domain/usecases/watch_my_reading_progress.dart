import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging show Logger;
import 'package:zapbook/core/data/repositories/circle_progress_repository.dart';
import 'package:zapbook/core/domain/entities/reading_progress.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';

@injectable
class WatchMyReadingProgressUseCase {
  WatchMyReadingProgressUseCase(this._repository, this._identity);
  final _log = logging.Logger('WatchMyReadingProgressUseCase');

  final CircleProgressRepository _repository;
  final IdentityLocalDataSource _identity;

  Stream<ReadingProgress?> call({
    required String groupId,
    required String bookId,
  }) async* {
    final myNpub = await _identity.readNpub();
    if (myNpub == null) {
      yield null;
      return;
    }
    yield* _repository
        .watchMyProgress(groupId: groupId, bookId: bookId, myNpub: myNpub)
        .handleError((error, stackTrace) {
          _log.warning('Error watching my reading progress', error, stackTrace);
        });
  }
}
