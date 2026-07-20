import 'package:zapbook/features/circles/domain/entities/admin_action_item.dart';

sealed class AdminActionsState {
  const AdminActionsState();
}

class AdminActionsLoading extends AdminActionsState {
  const AdminActionsLoading();
}

class AdminActionsLoaded extends AdminActionsState {
  const AdminActionsLoaded({
    required this.items,
    this.busyCircleDirIds = const {},
  });

  final List<AdminActionItem> items;
  final Set<String> busyCircleDirIds;

  bool isBusy(String circleDirId) => busyCircleDirIds.contains(circleDirId);
}
