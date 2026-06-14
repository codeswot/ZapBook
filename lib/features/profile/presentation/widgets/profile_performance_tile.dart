import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/performance/performance_service.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_tile.dart';
import 'package:zapbook/widgets/restart_widget.dart';

class ProfilePerformanceTile extends StatefulWidget {
  const ProfilePerformanceTile({super.key});

  @override
  State<ProfilePerformanceTile> createState() => _ProfilePerformanceTileState();
}

class _ProfilePerformanceTileState extends State<ProfilePerformanceTile> {
  final _perf = getIt<PerformanceService>();

  @override
  Widget build(BuildContext context) {
    return ProfileTile(
      icon: LucideIcons.gauge,
      title: 'Performance',
      subtitle: _subtitle(_perf.mode),
      onTap: _cycle,
    );
  }

  Future<void> _cycle() async {
    final next = PerfMode
        .values[(_perf.mode.index + 1) % PerfMode.values.length];
    await _perf.setMode(next);
    RestartWidget.restart();
  }

  String _subtitle(PerfMode mode) {
    switch (mode) {
      case PerfMode.auto:
        return _perf.deviceIsLegacy
            ? 'Auto · reduced on this device'
            : 'Auto · full effects';
      case PerfMode.on:
        return 'Reduced effects · best for older phones';
      case PerfMode.off:
        return 'Full effects';
    }
  }
}
