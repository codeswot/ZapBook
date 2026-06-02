import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/widgets/app_button.dart';
import 'package:zapbook/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:zapbook/core/services/ai_service.dart';
import 'package:zapbook/core/services/device_capability_service.dart';
import 'package:zapbook/core/di/injection.dart';

class ObFooter extends StatelessWidget {
  final OnboardingState state;
  final OnboardingCubit cubit;
  final DeviceCapability? capability;
  final AiModelState? aiState;
  final TextEditingController nsecController;
  final TextEditingController lnAddressController;
  final VoidCallback onComplete;

  const ObFooter({
    super.key,
    required this.state,
    required this.cubit,
    required this.capability,
    required this.aiState,
    required this.nsecController,
    required this.lnAddressController,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buildFooterButtons(context),
      ),
    );
  }

  List<Widget> _buildFooterButtons(BuildContext context) {
    switch (state.step) {
      case OnboardingStep.welcome:
        return [
          AppButton(
            label: "Get started",
            fullWidth: true,
            iconRight: LucideIcons.arrowRight,
            onTap: () => cubit.nextStep(),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: "I already have a key",
            variant: AppButtonVariant.ghost,
            fullWidth: true,
            onTap: () {
              cubit.toggleIdentityMode(false);
              cubit.selectStep(OnboardingStep.identity);
            },
          ),
        ];
      case OnboardingStep.identity:
        return [
          AppButton(
            label: state.isGeneratingNew ? "I've saved my key" : "Continue",
            variant: state.isGeneratingNew
                ? AppButtonVariant.purple
                : AppButtonVariant.primary,
            fullWidth: true,
            iconRight: LucideIcons.arrowRight,
            onTap: () {
              if (!state.isGeneratingNew &&
                  nsecController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter your secret key")),
                );
                return;
              }
              cubit.nextStep();
            },
          ),
          const SizedBox(height: 12),
          AppButton(
            label: state.isGeneratingNew
                ? "Import an existing nsec"
                : "Generate a new nsec",
            variant: AppButtonVariant.ghost,
            fullWidth: true,
            onTap: () => cubit.toggleIdentityMode(!state.isGeneratingNew),
          ),
        ];
      case OnboardingStep.wallet:
        return [
          AppButton(
            label: "Connect wallet",
            fullWidth: true,
            iconRight: LucideIcons.arrowRight,
            onTap: () {
              if (lnAddressController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please enter a Lightning address"),
                  ),
                );
                return;
              }
              cubit.nextStep();
            },
          ),
          const SizedBox(height: 12),
          AppButton(
            label: "Skip — set up later",
            variant: AppButtonVariant.ghost,
            fullWidth: true,
            onTap: () => cubit.nextStep(),
          ),
        ];
      case OnboardingStep.model:
        final status = aiState?.status ?? AiModelStatus.notSet;
        final isDownloading = status == AiModelStatus.downloading;
        final isReady = status == AiModelStatus.ready;
        final isCapable = capability != DeviceCapability.incapable;

        if (!isCapable) {
          return [
            AppButton(
              label: "Continue",
              fullWidth: true,
              iconRight: LucideIcons.check,
              onTap: onComplete,
            ),
          ];
        }

        return [
          AppButton(
            label: (isReady || isDownloading) ? "Continue" : "Download model",
            fullWidth: true,
            variant: AppButtonVariant.purple,
            iconRight: isReady
                ? LucideIcons.check
                : isDownloading
                ? LucideIcons.arrowRight
                : LucideIcons.download,
            onTap: (isReady || isDownloading)
                ? onComplete
                : () async {
                    final url = capability?.modelUrl;
                    final hash = capability?.expectedHash;
                    if (url != null && hash != null) {
                      await getIt<AiService>().startDownload(url, hash);
                    } else {
                      await getIt<AiService>().skipSetup();
                      onComplete();
                    }
                  },
          ),
          const SizedBox(height: 12),
          AppButton(
            label: "Skip for now",
            variant: AppButtonVariant.ghost,
            fullWidth: true,
            onTap: onComplete,
          ),
        ];
    }
  }
}
