import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/core/cubit/ai_model_cubit.dart';
import 'package:zapbook/core/services/ai_service.dart';
import 'package:zapbook/core/services/device_capability_service.dart';
import 'package:zapbook/core/domain/validators.dart';
import 'package:zapbook/widgets/app_button.dart';
import 'package:zapbook/features/onboarding/presentation/bloc/onboarding_cubit.dart';
import 'package:zapbook/widgets/app_toast.dart';

class ObFooter extends StatelessWidget {
  final OnboardingState state;
  final OnboardingCubit cubit;
  final DeviceCapability? capability;
  final AiModelState? aiState;
  final TextEditingController nsecController;
  final TextEditingController lnAddressController;
  final TextEditingController displayNameController;
  final VoidCallback onComplete;

  const ObFooter({
    super.key,
    required this.state,
    required this.cubit,
    required this.capability,
    required this.aiState,
    required this.nsecController,
    required this.lnAddressController,
    required this.displayNameController,
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
            iconRight: state.isBusy ? null : LucideIcons.arrowRight,
            isLoading: state.isBusy && !state.isGeneratingNew,
            onTap: () async {
              if (state.isGeneratingNew) {
                if (state.generatedNpub.isEmpty) {
                  context.toast.showError("Generating your key, one moment…");
                  return;
                }
              } else {
                final imported = await cubit.importNsec(nsecController.text);
                if (!imported) {
                  if (context.mounted) {
                    context.toast.showError(
                      cubit.state.error ?? "Invalid secret key",
                    );
                  }
                  return;
                }
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
              final addr = lnAddressController.text.trim();
              if (addr.isEmpty) {
                context.toast.showError("Please enter a Lightning address");
                return;
              }
              final error = Validators.lud16(addr);
              if (error != null) {
                context.toast.showError(error);
                return;
              }
              cubit.updateLightningAddress(addr);
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
        final isCapable = capability != null &&
            capability != DeviceCapability.incapable;

        if (capability == null) {
          return [
            AppButton(
              label: "Detecting device…",
              fullWidth: true,
              isLoading: true,
            ),
          ];
        }

        if (!isCapable) {
          return [
            AppButton(
              label: "Continue",
              fullWidth: true,
              iconRight: LucideIcons.arrowRight,
              onTap: () => cubit.nextStep(),
            ),
          ];
        }

        return [
          AppButton(
            label: (isReady || isDownloading) ? "Continue" : "Download model",
            fullWidth: true,
            variant: AppButtonVariant.purple,
            iconRight: isReady
                ? LucideIcons.arrowRight
                : isDownloading
                ? LucideIcons.arrowRight
                : LucideIcons.download,
            onTap: (isReady || isDownloading)
                ? () => cubit.nextStep()
                : () async {
                    final url = capability?.modelUrl;
                    final hash = capability?.expectedHash;
                    final ai = context.read<AiModelCubit>();
                    if (url != null && hash != null) {
                      ai.startDownload(url, hash);
                    } else {
                      ai.skipSetup();
                      cubit.nextStep();
                    }
                  },
          ),
          const SizedBox(height: 12),
          AppButton(
            label: "Skip for now",
            variant: AppButtonVariant.ghost,
            fullWidth: true,
            onTap: () => cubit.nextStep(),
          ),
        ];
      case OnboardingStep.profile:
        return [
          AppButton(
            label: "Continue",
            fullWidth: true,
            variant: AppButtonVariant.purple,
            iconRight: state.isBusy ? null : LucideIcons.check,
            isLoading: state.isBusy,
            onTap: onComplete,
          ),
          if (!state.isBusy) ...[
            const SizedBox(height: 12),
            AppButton(
              label: "Skip",
              variant: AppButtonVariant.ghost,
              fullWidth: true,
              onTap: onComplete,
            ),
          ],
        ];
    }
  }
}
