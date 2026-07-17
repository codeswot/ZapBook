import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/data/infrastructure/local_notification_service.dart';
import 'package:zapbook/core/data/infrastructure/notification_gate.dart';
import 'package:zapbook/core/data/infrastructure/sync_service_channel.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_tile.dart';

class ProfileNotificationsTile extends StatefulWidget {
  const ProfileNotificationsTile({super.key});

  @override
  State<ProfileNotificationsTile> createState() =>
      _ProfileNotificationsTileState();
}

class _ProfileNotificationsTileState extends State<ProfileNotificationsTile> {
  final _gate = getIt<NotificationGate>();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final enabled = _gate.isEnabled;

    return ProfileTile(
      icon: LucideIcons.bell,
      title: 'Notifications',
      subtitle: enabled
          ? 'Circle activity, zaps and invites'
          : 'Off — you may miss circle activity',
      showChevron: false,
      trailing: Switch.adaptive(
        value: enabled,
        onChanged: _busy ? null : (value) => _toggle(value),
      ),
      onTap: _busy ? null : () => _toggle(!enabled),
    );
  }

  Future<void> _toggle(bool value) async {
    setState(() => _busy = true);
    try {
      if (value) {
        final granted = await getIt<LocalNotificationService>()
            .requestPermission();
        if (!granted) return;
        await _gate.setEnabled(true);
        await getIt<SyncServiceChannel>().requestIgnoreBatteryOptimizations();
      } else {
        await _gate.setEnabled(false);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
