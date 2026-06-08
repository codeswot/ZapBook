import 'package:zapbook/features/home/domain/entities/home_dashboard.dart';

abstract interface class HomeDashboardRepository {
  Stream<HomeDashboard> watchDashboard();
  Future<void> touchBookOpened(String bookId);
}
