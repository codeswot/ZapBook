import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';

abstract interface class CheersRepository {
  Stream<List<CheersActivity>> watchActivities();
  Future<void> sendZap(String activityId, int amount, String reactionType);
}
