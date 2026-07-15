import 'package:injectable/injectable.dart';
import 'package:zapbook/core/data/database/dao/zap_sats_earnings_dao.dart';
import 'package:zapbook/core/domain/repositories/earnings_repository.dart';

@LazySingleton(as: EarningsRepository)
class EarningsRepositoryImpl implements EarningsRepository {
  final ZapSatsEarningsDao _dao;

  EarningsRepositoryImpl(this._dao);

  @override
  Future<int> getTotalSats(String npub) => _dao.getTotalSats(npub);

  @override
  Stream<int> watchTotalSats(String npub) => _dao.watchTotalSats(npub);
}
