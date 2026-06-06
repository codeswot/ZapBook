import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/core/services/ai_service.dart';
import 'package:zapbook/core/services/device_capability_service.dart';
import 'package:zapbook/features/onboarding/presentation/widgets/ob_banner.dart';
import 'package:zapbook/features/onboarding/presentation/widgets/ob_step_intro.dart';

class ObModelView extends StatelessWidget {
  final DeviceCapability? capability;
  final AiModelState? aiState;

  const ObModelView({
    super.key,
    required this.capability,
    required this.aiState,
  });

  @override
  Widget build(BuildContext context) {
    final status = aiState?.status ?? AiModelStatus.notSet;
    final isDownloading = status == AiModelStatus.downloading;
    final isReady = status == AiModelStatus.ready;
    final isCapable = capability != null &&
        capability != DeviceCapability.incapable;

    final modelName = capability?.modelName ?? 'Checking device…';
    final modelSize = capability?.expectedFileSize != null
        ? '${(capability!.expectedFileSize! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB'
        : '…';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ObStepIntro(
          icon: LucideIcons.cpu,
          accentColor: context.colors.plum,
          accentDim: context.colors.plumTint,
          accentLine: context.colors.plumTint2,
          over: "Step 3 · On-device AI",
          title: "Reading checks, on your phone",
          description:
              "ZapBook uses a small AI model to turn books into clean pages and write the milestone quizzes — running entirely on your device.",
        ),
        const SizedBox(height: 26),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.paper2,
            borderRadius: AppRadii.br18,
            border: Border.all(color: context.colors.hairline),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: context.colors.plumTint,
                      borderRadius: AppRadii.br14,
                      border: Border.all(color: context.colors.plumTint2),
                    ),
                    child: Icon(
                      LucideIcons.sparkles,
                      color: context.colors.plum,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          modelName,
                          style: context.typography.bodyL.copyWith(
                            fontWeight: FontWeight.w700,
                            color: context.colors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$modelSize · runs offline",
                          style: context.typography.bodyS.copyWith(
                            color: context.colors.slate,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isCapable)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isReady
                            ? context.colors.positive.withValues(alpha: 0.15)
                            : context.colors.positive.withValues(alpha: 0.1),
                        borderRadius: AppRadii.br999,
                        border: Border.all(
                          color: context.colors.positive.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.check,
                            size: 13,
                            color: context.colors.positive,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isReady ? "Ready" : "Supported",
                            style: context.typography.bodyS.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.colors.positive,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (isDownloading) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: AppRadii.br999,
                  child: LinearProgressIndicator(
                    value: aiState?.downloadProgress ?? 0.0,
                    minHeight: 6,
                    backgroundColor: context.colors.paper3,
                    color: context.colors.plum,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      status == AiModelStatus.verifying
                          ? "Verifying..."
                          : "Downloading model...",
                      style: context.typography.bodyS.copyWith(
                        color: context.colors.slate,
                      ),
                    ),
                    Text(
                      "${((aiState?.downloadProgress ?? 0.0) * 100).toInt()}%",
                      style: context.typography.mono.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        color: context.colors.slate,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        ObBanner(
          icon: LucideIcons.info,
          title: "Nothing leaves your device",
          description:
              "Books, quizzes, and your reading are processed locally. ZapBook never uploads them.",
          backgroundColor: context.colors.plumTint,
          iconColor: context.colors.plum,
          borderColor: context.colors.plum.withValues(alpha: 0.2),
        ),
      ],
    );
  }
}
