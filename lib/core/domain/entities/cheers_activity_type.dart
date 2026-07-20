enum CheersActivityType {
  milestone,
  cheer,
  zap,
  zapNudge,
  zapReady,
  notification,
  adminAction,
  unknown;

  static CheersActivityType fromString(String val) {
    switch (val) {
      case 'milestone':
        return milestone;
      case 'cheer':
        return cheer;
      case 'zap':
        return zap;
      case 'zap_nudge':
        return zapNudge;
      case 'zap_ready':
        return zapReady;
      case 'notification':
        return notification;
      case 'admin_action':
        return adminAction;
      default:
        return unknown;
    }
  }

  String get value {
    switch (this) {
      case milestone:
        return 'milestone';
      case cheer:
        return 'cheer';
      case zap:
        return 'zap';
      case zapNudge:
        return 'zap_nudge';
      case zapReady:
        return 'zap_ready';
      case notification:
        return 'notification';
      case adminAction:
        return 'admin_action';
      case unknown:
        return 'unknown';
    }
  }
}
