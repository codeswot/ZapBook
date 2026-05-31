import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/services/ai_service.dart';
import 'package:zapbook/theme/app_theme.dart';

class AppBanner extends StatelessWidget {
  const AppBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final aiService = getIt<AiService>();

    return StreamBuilder<AiModelState>(
      stream: aiService.aiState,
      initialData: aiService.currentState,
      builder: (context, snapshot) {
        final state = snapshot.data;
        if (state == null || state.status == AiModelStatus.ready || state.bannerDismissed) {
          return const SizedBox.shrink();
        }

        if (state.status == AiModelStatus.downloading || state.status == AiModelStatus.paused) {
          return _buildDownloadingBanner(context, aiService, state);
        }

        if (state.status == AiModelStatus.verifying) {
          return _buildVerifyingBanner(context);
        }

        if (state.status == AiModelStatus.notSet || state.status == AiModelStatus.skipped) {
          return _buildMissingBanner(context, aiService);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildDownloadingBanner(BuildContext context, AiService aiService, AiModelState state) {
    final progress = state.downloadProgress;
    final isPaused = state.status == AiModelStatus.paused;
    final percent = (progress * 100).toStringAsFixed(0);
    
    return Container(
      color: context.colors.plum.withValues(alpha: 0.1),
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 8,
        bottom: 8,
        left: 16,
        right: 16,
      ),
      child: Row(
        children: [
          SizedBox(
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
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isPaused 
                ? 'AI Model Paused ($percent%)'
                : 'Downloading AI Model ($percent%)...',
              style: context.typography.bodyS.copyWith(color: context.colors.plum),
            ),
          ),
          GestureDetector(
            onTap: isPaused ? aiService.resumeDownload : aiService.pauseDownload,
            child: Icon(
              isPaused ? LucideIcons.play : LucideIcons.pause, 
              color: context.colors.plum, 
              size: 20
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyingBanner(BuildContext context) {
    return Container(
      color: context.colors.mintTint.withValues(alpha: 0.2),
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 8,
        bottom: 8,
        left: 16,
        right: 16,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.colors.mint2,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Verifying AI Model hash...',
              style: context.typography.bodyS.copyWith(color: context.colors.mint2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingBanner(BuildContext context, AiService aiService) {
    return Container(
      color: context.colors.coralTint,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 8,
        bottom: 8,
        left: 16,
        right: 16,
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertCircle, color: context.colors.tomato, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'AI model missing. Tap to set it up.',
              style: context.typography.bodyS.copyWith(color: context.colors.tomato),
            ),
          ),
          GestureDetector(
            onTap: aiService.dismissBanner,
            child: Icon(LucideIcons.x, color: context.colors.slate, size: 20),
          ),
        ],
      ),
    );
  }
}
