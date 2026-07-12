import 'dart:async';

typedef MilestoneSnapshot = ({
  int page,
  int words,
  int milestones,
  bool completed,
});
typedef MilestoneReport = ({
  String npub,
  String groupId,
  double fraction,
  int totalWords,
  MilestoneSnapshot snapshot,
  int nowMs,
});

class MilestoneBookSession {
  Timer? debounce;
  MilestoneReport? pending;
  MilestoneSnapshot? lastSent;

  void cancelDebounce() {
    debounce?.cancel();
    debounce = null;
  }
}
