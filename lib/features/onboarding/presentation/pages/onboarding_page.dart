import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/services/ai_service.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_fade_overlay.dart';
import 'package:zapbook/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:zapbook/features/ai_model/presentation/cubit/ai_model_cubit.dart';
import 'package:zapbook/features/onboarding/presentation/widgets/ob_header.dart';
import 'package:zapbook/features/onboarding/presentation/widgets/ob_footer.dart';
import 'package:zapbook/features/onboarding/presentation/widgets/ob_welcome_view.dart';
import 'package:zapbook/features/onboarding/presentation/widgets/ob_identity_view.dart';
import 'package:zapbook/features/onboarding/presentation/widgets/ob_wallet_view.dart';
import 'package:zapbook/features/onboarding/presentation/widgets/ob_model_view.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<OnboardingCubit>(create: (_) => getIt<OnboardingCubit>()),
        BlocProvider<AiModelCubit>(create: (_) => getIt<AiModelCubit>()),
      ],
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatefulWidget {
  const _OnboardingView();

  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView> {
  final TextEditingController _nsecController = TextEditingController();
  final TextEditingController _lnAddressController = TextEditingController();

  @override
  void dispose() {
    _nsecController.dispose();
    _lnAddressController.dispose();
    super.dispose();
  }

  void _onComplete(BuildContext context, OnboardingCubit cubit) async {
    final saved = await cubit.completeOnboarding();
    if (saved && context.mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();

    return BlocBuilder<AiModelCubit, AiModelState>(
      builder: (context, aiState) {
        return BlocBuilder<OnboardingCubit, OnboardingState>(
          builder: (context, state) {
            final currentStepIndex = _getStepIndex(state.step);

            return Scaffold(
              backgroundColor: context.colors.paper,
              body: SafeArea(
                child: Column(
                  children: [
                    if (currentStepIndex > 0)
                      ObHeader(
                        currentStep: currentStepIndex,
                        onBack: () => cubit.previousStep(),
                      ),
                    Expanded(
                      child: Stack(
                        children: [
                          SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            child: _buildStepContent(state, cubit, aiState),
                          ),
                          AppFadeOverlay.top(
                            color: context.colors.paper,
                            height: 16,
                          ),
                          AppFadeOverlay.bottom(
                            color: context.colors.paper,
                            height: 16,
                          ),
                        ],
                      ),
                    ),
                    ObFooter(
                      state: state,
                      cubit: cubit,
                      capability: aiState.capability,
                      aiState: aiState,
                      nsecController: _nsecController,
                      lnAddressController: _lnAddressController,
                      onComplete: () => _onComplete(context, cubit),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  int _getStepIndex(OnboardingStep step) {
    switch (step) {
      case OnboardingStep.welcome:
        return 0;
      case OnboardingStep.identity:
        return 1;
      case OnboardingStep.wallet:
        return 2;
      case OnboardingStep.model:
        return 3;
    }
  }

  Widget _buildStepContent(
    OnboardingState state,
    OnboardingCubit cubit,
    AiModelState aiState,
  ) {
    switch (state.step) {
      case OnboardingStep.welcome:
        return const ObWelcomeView();
      case OnboardingStep.identity:
        return ObIdentityView(
          state: state,
          cubit: cubit,
          nsecController: _nsecController,
        );
      case OnboardingStep.wallet:
        return ObWalletView(
          state: state,
          cubit: cubit,
          lnAddressController: _lnAddressController,
        );
      case OnboardingStep.model:
        return ObModelView(capability: aiState.capability, aiState: aiState);
    }
  }
}
