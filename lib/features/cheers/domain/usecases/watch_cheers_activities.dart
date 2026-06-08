import 'package:injectable/injectable.dart';
import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';
import 'package:zapbook/features/cheers/domain/repositories/cheers_repository.dart';

@injectable
final class WatchCheersActivities {
  const WatchCheersActivities(this._repository);

  final CheersRepository _repository;

  Stream<List<CheersActivity>> call() => _repository.watchActivities();
}
