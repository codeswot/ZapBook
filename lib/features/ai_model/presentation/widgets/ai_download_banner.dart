import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/core/services/ai_service.dart';
import 'package:zapbook/features/ai_model/presentation/cubit/ai_model_cubit.dart';
import 'package:zapbook/features/ai_model/presentation/widgets/ai_verifying_banner.dart';
import 'package:zapbook/features/heads_up/presentation/cubit/heads_up_cubit.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_banner.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class AiDownloadBanner extends StatelessWidget {
  const AiDownloadBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AiModelCubit, AiModelState>(
      listener: (context, state) {
        if (state.status == AiModelStatus.ready) {
          context.read<HeadsUpCubit>().dismissBanner('ai_model');
        }
      },
      builder: (context, state) {
        if (state.status == AiModelStatus.verifying) {
          return const AiVerifyingBanner();
        }
        final cubit = context.read<AiModelCubit>();
        final progress = state.downloadProgress;
        final isPaused = state.status == AiModelStatus.paused;
        final percent = (progress * 100).toStringAsFixed(0);

        return AppBanner(
          backgroundColor: context.colors.plum.withValues(alpha: 0.1),
          leading: SizedBox(
            width: 16,
            height: 16,
            child: isPaused
                ? Icon(LucideIcons.pause, size: 16, color: context.colors.plum)
                : CircularProgressIndicator(
                    strokeWidth: 2,
                    value: progress > 0 ? progress : null,
                    color: context.colors.plum,
                  ),
          ),
          title: Text(
            isPaused
                ? 'AI Model Paused ($percent%)'
                : 'Downloading AI Model ($percent%)...',
            style: context.typography.bodyS.copyWith(
              color: context.colors.plum,
            ),
          ),
          trailing: BouncingInteractiveWidget(
            onTap: isPaused ? cubit.resumeDownload : cubit.pauseDownload,
            child: Icon(
              isPaused ? LucideIcons.play : LucideIcons.pause,
              color: context.colors.plum,
              size: 20,
            ),
          ),
        );
      },
    );
  }
}
