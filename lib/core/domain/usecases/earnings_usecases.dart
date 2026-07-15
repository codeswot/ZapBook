import 'package:injectable/injectable.dart';
import 'package:zapbook/core/domain/repositories/earnings_repository.dart';
import 'package:zapbook/core/identity/identity_repository.dart';

@injectable
class WatchEarningsUseCase {
  final EarningsRepository _repo;
  final IdentityRepository _identity;

  WatchEarningsUseCase(this._repo, this._identity);

  Stream<int> call() async* {
    final npub = await _identity.currentNpub();
    if (npub == null) {
      yield 0;
      return;
    }
    yield* _repo.watchTotalSats(npub);
  }
}

@injectable
class GetEarningsUseCase {
  final EarningsRepository _repo;
  final IdentityRepository _identity;

  GetEarningsUseCase(this._repo, this._identity);

  Future<int> call() async {
    final npub = await _identity.currentNpub();
    if (npub == null) return 0;
    return _repo.getTotalSats(npub);
  }
}
