import 'package:injectable/injectable.dart';
import 'package:zapbook/core/data/dao/circle_progress_dao.dart';
import 'package:zapbook/core/domain/entities/reading_progress.dart';
import 'package:zapbook/core/models/circle_member_progress.dart';

abstract interface class CircleProgressDataSource {
  Stream<ReadingProgress?> watchMyProgress({
    required String groupId,
    required String bookId,
    required String myNpub,
  });
}

@LazySingleton(as: CircleProgressDataSource)
class CircleProgressDataSourceImpl implements CircleProgressDataSource {
  CircleProgressDataSourceImpl(this._dao);

  final CircleProgressDao _dao;

  @override
  Stream<ReadingProgress?> watchMyProgress({
    required String groupId,
    required String bookId,
    required String myNpub,
  }) {
    return _dao
        .watchMyProgress(groupId: groupId, bookId: bookId, myNpub: myNpub)
        .map(_toEntity);
  }

  ReadingProgress? _toEntity(CircleMemberProgress? row) {
    if (row == null) return null;
    return ReadingProgress(
      pubKey: row.pubKey,
      bookId: row.bookId,
      page: row.pageIndex,
      fraction: row.progressPercentage,
      updatedAt: row.updatedAt,
      milestonesReached: row.milestonesReached,
      completed: row.completed,
    );
  }
}
