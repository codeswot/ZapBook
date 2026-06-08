import 'package:injectable/injectable.dart';
import 'package:zapbook/features/home/domain/entities/home_dashboard.dart';
import 'package:zapbook/features/home/domain/repositories/home_dashboard_repository.dart';

@injectable
final class WatchHomeDashboard {
  const WatchHomeDashboard(this._repository);

  final HomeDashboardRepository _repository;

  Stream<HomeDashboard> call() => _repository.watchDashboard();
}
