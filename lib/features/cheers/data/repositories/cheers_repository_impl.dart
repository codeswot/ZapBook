import 'package:injectable/injectable.dart';
import 'package:zapbook/features/cheers/data/datasources/cheers_data_source.dart';
import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';
import 'package:zapbook/features/cheers/domain/repositories/cheers_repository.dart';

@LazySingleton(as: CheersRepository)
class CheersRepositoryImpl implements CheersRepository {
  const CheersRepositoryImpl(this._dataSource);

  final CheersDataSource _dataSource;

  @override
  Stream<List<CheersActivity>> watchActivities() =>
      _dataSource.watchActivities();

  @override
  Future<void> sendZap(String activityId, int amount, String reactionType) =>
      _dataSource.sendZap(activityId, amount, reactionType);

  @override
  void loadMore() => _dataSource.bumpLimit();
}
