import 'package:injectable/injectable.dart';
import 'package:zapbook/features/home/data/datasources/home_dashboard_data_source.dart';
import 'package:zapbook/features/home/domain/entities/home_dashboard.dart';
import 'package:zapbook/features/home/domain/repositories/home_dashboard_repository.dart';

@LazySingleton(as: HomeDashboardRepository)
class HomeDashboardRepositoryImpl implements HomeDashboardRepository {
  const HomeDashboardRepositoryImpl(this._dataSource);

  final HomeDashboardDataSource _dataSource;

  @override
  Stream<HomeDashboard> watchDashboard() => _dataSource.watchDashboard();

  @override
  Future<void> touchBookOpened(String bookId) =>
      _dataSource.touchBookOpened(bookId);
}
