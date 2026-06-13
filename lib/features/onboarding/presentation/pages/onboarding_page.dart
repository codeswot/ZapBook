import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/router/app_router.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_fade_overlay.dart';
import 'package:zapbook/widgets/app_toast.dart';
import 'package:zapbook/features/onboarding/presentation/bloc/onboarding_cubit.dart';
import 'package:zapbook/features/onboarding/presentation/widgets/ob_header.dart';
import 'package:zapbook/features/onboarding/presentation/widgets/ob_footer.dart';
import 'package:zapbook/features/onboarding/presentation/widgets/ob_welcome_view.dart';
import 'package:zapbook/features/onboarding/presentation/widgets/ob_identity_view.dart';
import 'package:zapbook/features/onboarding/presentation/widgets/ob_wallet_view.dart';
import 'package:zapbook/features/onboarding/presentation/widgets/ob_profile_view.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OnboardingCubit>(
      create: (_) => getIt<OnboardingCubit>(),
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
  final TextEditingController _displayNameController = TextEditingController();

  @override
  void dispose() {
    _nsecController.dispose();
    _lnAddressController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _onComplete(
    BuildContext context,
    OnboardingCubit cubit, {
    required bool publish,
  }) async {
    final saved = await cubit.completeOnboarding(publish: publish);
    if (saved && context.mounted) {
      const HomeRoute().go(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();

    return BlocListener<OnboardingCubit, OnboardingState>(
      listener: (context, state) {
        if (state.isComplete) {
          if (state.keyPackagePublishFailed) {
            AppToast.show(
              context,
              message:
                  "Couldn't finish setting you up for reading circles. "
                  "Reopen the app to retry.",
              type: AppToastType.warning,
              rootNavigator: true,
            );
          }
          const HomeRoute().go(context);
        }
      },
      child: BlocBuilder<OnboardingCubit, OnboardingState>(
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
                          child: _OnboardingStepContent(
                            state: state,
                            cubit: cubit,
                            nsecController: _nsecController,
                            lnAddressController: _lnAddressController,
                            displayNameController: _displayNameController,
                          ),
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
                    nsecController: _nsecController,
                    lnAddressController: _lnAddressController,
                    displayNameController: _displayNameController,
                    onComplete: (publish) =>
                        _onComplete(context, cubit, publish: publish),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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
      case OnboardingStep.profile:
        return 3;
    }
  }
}

class _OnboardingStepContent extends StatelessWidget {
  const _OnboardingStepContent({
    required this.state,
    required this.cubit,
    required this.nsecController,
    required this.lnAddressController,
    required this.displayNameController,
  });

  final OnboardingState state;
  final OnboardingCubit cubit;
  final TextEditingController nsecController;
  final TextEditingController lnAddressController;
  final TextEditingController displayNameController;

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
        if (lnAddressController.text.isEmpty &&
            state.lightningAddress.isNotEmpty) {
          lnAddressController.text = state.lightningAddress;
        }
        return ObWalletView(
          state: state,
          cubit: cubit,
          lnAddressController: lnAddressController,
        );
      case OnboardingStep.profile:
        if (displayNameController.text != state.displayName) {
          displayNameController.text = state.displayName;
        }
        return ObProfileView(
          state: state,
          cubit: cubit,
          displayNameController: displayNameController,
        );
    }
  }
}
