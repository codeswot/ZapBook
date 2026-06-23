import 'package:injectable/injectable.dart';
import 'package:zapbook/features/cheers/domain/repositories/cheers_repository.dart';

@injectable
final class LoadMoreCheersActivities {
  const LoadMoreCheersActivities(this._repository);

  final CheersRepository _repository;

  void call() => _repository.loadMore();
}
