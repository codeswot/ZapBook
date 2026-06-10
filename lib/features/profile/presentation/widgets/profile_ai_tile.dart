import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/core/services/ai_model_service.dart';
import 'package:zapbook/core/services/device_capability_service.dart';
import 'package:zapbook/core/cubit/ai_model_cubit.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_ai_manage_sheet.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_status_pill.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_tile.dart';
import 'package:zapbook/theme/app_theme.dart';

class ProfileAiTile extends StatelessWidget {
  const ProfileAiTile({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = context.watch<AiModelCubit>().state;
    final status = state.status;
    final ready = status == AiModelStatus.ready;
    final name = state.capability?.modelName ?? 'AI model';
    final subtitle = status == AiModelStatus.downloading
        ? '${_label(status)} · ${(state.downloadProgress * 100).toInt()}%'
        : _label(status);

    return ProfileTile(
      icon: LucideIcons.cpu,
      title: 'AI Model',
      subtitle: '$name · $subtitle',
      trailing: ProfileStatusPill(
        label: ready ? 'On' : 'Off',
        color: ready ? colors.positive : colors.slate2,
      ),
      onTap: () => ProfileAiManageSheet.show(context),
    );
  }

  String _label(AiModelStatus status) {
    switch (status) {
      case AiModelStatus.ready:
        return 'Ready';
      case AiModelStatus.downloading:
        return 'Downloading';
      case AiModelStatus.paused:
        return 'Paused';
      case AiModelStatus.verifying:
        return 'Verifying';
      case AiModelStatus.skipped:
        return 'Disabled';
      case AiModelStatus.notSet:
        return 'Not set';
    }
  }
}
