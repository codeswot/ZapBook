import 'package:injectable/injectable.dart';
import 'package:zapbook/core/data/datasources/circle_progress_data_source.dart';
import 'package:zapbook/core/domain/entities/reading_progress.dart';

@lazySingleton
class CircleProgressRepository {
  CircleProgressRepository(this._dataSource);

  final CircleProgressDataSource _dataSource;

  Stream<ReadingProgress?> watchMyProgress({
    required String groupId,
    required String bookId,
    required String myNpub,
  }) {
    return _dataSource.watchMyProgress(
      groupId: groupId,
      bookId: bookId,
      myNpub: myNpub,
    );
  }
}
