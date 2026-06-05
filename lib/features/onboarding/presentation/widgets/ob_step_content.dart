import 'package:flutter/material.dart';
import 'package:zapbook/core/services/device_capability_service.dart';
import 'package:zapbook/core/services/ai_service.dart';
import 'package:zapbook/features/onboarding/presentation/bloc/onboarding_cubit.dart';
import 'package:zapbook/features/onboarding/presentation/widgets/ob_welcome_view.dart';
import 'package:zapbook/features/onboarding/presentation/widgets/ob_identity_view.dart';
import 'package:zapbook/features/onboarding/presentation/widgets/ob_wallet_view.dart';
import 'package:zapbook/features/onboarding/presentation/widgets/ob_model_view.dart';

class ObStepContent extends StatelessWidget {
  final OnboardingState state;
  final OnboardingCubit cubit;
  final DeviceCapability? capability;
  final AiModelState? aiState;
  final TextEditingController nsecController;
  final TextEditingController lnAddressController;

  const ObStepContent({
    super.key,
    required this.state,
    required this.cubit,
    required this.capability,
    required this.aiState,
    required this.nsecController,
    required this.lnAddressController,
  });

  @override
  Widget build(BuildContext context) {
    switch (state.step) {
      case OnboardingStep.welcome:
        return const ObWelcomeView();
      case OnboardingStep.identity:
        return ObIdentityView(
          state: state,
          cubit: cubit,
          nsecController: nsecController,
        );
      case OnboardingStep.wallet:
        return ObWalletView(
          state: state,
          cubit: cubit,
          lnAddressController: lnAddressController,
        );
      case OnboardingStep.model:
        return ObModelView(
          capability: capability,
          aiState: aiState,
        );
      case OnboardingStep.profile:
        return const SizedBox.shrink();
    }
  }
}
