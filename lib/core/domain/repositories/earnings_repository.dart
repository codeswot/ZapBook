abstract class EarningsRepository {
  Future<int> getTotalSats(String npub);
  Stream<int> watchTotalSats(String npub);
}
