import 'package:injectable/injectable.dart';
import 'package:zapbook/features/home/domain/repositories/home_dashboard_repository.dart';

@injectable
final class TouchDashboardBookOpened {
  const TouchDashboardBookOpened(this._repository);

  final HomeDashboardRepository _repository;

  Future<void> call(String bookId) => _repository.touchBookOpened(bookId);
}
