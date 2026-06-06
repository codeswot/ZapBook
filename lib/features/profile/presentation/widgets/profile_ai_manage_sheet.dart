import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/core/cubit/ai_model_cubit.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/services/ai_service.dart';
import 'package:zapbook/core/services/device_capability_service.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_button.dart';
import 'package:zapbook/widgets/app_sheet.dart';

class ProfileAiManageSheet extends StatelessWidget {
  const ProfileAiManageSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(value: getIt<AiModelCubit>(), child: _Content());
  }

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProfileAiManageSheet(),
    );
  }
}

class _Content extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AiModelCubit>().state;
    final cubit = context.read<AiModelCubit>();
    final status = state.status;
    final capability = state.capability;

    final modelName = capability?.modelName ?? 'Unknown model';
    final modelSize = capability?.expectedFileSize != null
        ? '${(capability!.expectedFileSize! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB'
        : '—';
    final progress = state.downloadProgress > 0
        ? '${(state.downloadProgress * 100).toInt()}%'
        : null;

    return AppSheet(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'AI Model',
              style: context.typography.displayM.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              modelName,
              style: context.typography.bodyL.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colors.slate,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$modelSize · ${_statusLabel(status)}${progress != null ? ' · $progress' : ''}',
              style: context.typography.bodyS.copyWith(
                color: context.colors.slate,
              ),
            ),
            const SizedBox(height: 20),
            if (capability == null)
              AppButton(
                label: 'Device not supported',
                fullWidth: true,
                onTap: null,
              )
            else ...[
              if (status == AiModelStatus.notSet ||
                  status == AiModelStatus.skipped) ...[
                AppButton(
                  label: 'Download model',
                  fullWidth: true,
                  variant: AppButtonVariant.purple,
                  icon: LucideIcons.download,
                  onTap: () {
                    final url = capability.modelUrl;
                    final hash = capability.expectedHash;
                    if (url != null && hash != null) {
                      cubit.startDownload(url, hash);
                    }
                  },
                ),
              ],
              if (status == AiModelStatus.downloading) ...[
                AppButton(
                  label: 'Pause download',
                  fullWidth: true,
                  variant: AppButtonVariant.tonal,
                  icon: LucideIcons.pause,
                  onTap: cubit.pauseDownload,
                ),
              ],
              if (status == AiModelStatus.paused) ...[
                AppButton(
                  label: 'Resume download',
                  fullWidth: true,
                  variant: AppButtonVariant.tonal,
                  icon: LucideIcons.play,
                  onTap: cubit.resumeDownload,
                ),
              ],
              if (status == AiModelStatus.ready ||
                  status == AiModelStatus.verifying) ...[
                AppButton(
                  label: 'Offload model',
                  fullWidth: true,
                  variant: AppButtonVariant.tonal,
                  icon: LucideIcons.trash2,
                  onTap: cubit.reset,
                ),
              ],
              if (status == AiModelStatus.downloading ||
                  status == AiModelStatus.paused) ...[
                const SizedBox(height: 12),
                AppButton(
                  label: 'Cancel download',
                  fullWidth: true,
                  variant: AppButtonVariant.ghost,
                  onTap: cubit.cancelDownload,
                ),
              ],
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _statusLabel(AiModelStatus status) {
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
        return 'Skipped';
      case AiModelStatus.notSet:
        return 'Not set';
    }
  }
}
