import 'package:flutter/material.dart';
import 'package:zapbook/features/onboarding/presentation/widgets/ai_setup_view.dart';
import 'package:zapbook/features/onboarding/presentation/widgets/nostr_setup_view.dart';
import 'package:zapbook/features/onboarding/presentation/widgets/welcome_view.dart';
import 'package:zapbook/theme/app_theme.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.paper,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          WelcomeView(onNext: _nextPage),
          NostrSetupView(onNext: _nextPage),
          const AiSetupView(),
        ],
      ),
    );
  }
}
