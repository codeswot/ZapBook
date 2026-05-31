import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/services/ai_service.dart';
import 'package:zapbook/core/services/device_capability_service.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_button.dart';

class AiSetupView extends StatefulWidget {
  const AiSetupView({super.key});

  @override
  State<AiSetupView> createState() => _AiSetupViewState();
}

class _AiSetupViewState extends State<AiSetupView> {
  DeviceCapability? _capability;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkCapability();
  }

  Future<void> _checkCapability() async {
    final capabilityService = getIt<DeviceCapabilityService>();
    final capability = await capabilityService.checkDeviceCapability();
    
    if (mounted) {
      setState(() {
        _capability = capability;
        _isLoading = false;
      });
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = getIt<SharedPreferences>();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isCapable = _capability != DeviceCapability.incapable;
    final modelName = _capability == DeviceCapability.capable4B ? 'Gemma 4B' : 'Gemma 2B';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Icon(
              LucideIcons.bot,
              size: 80,
              color: context.colors.plum,
            ),
            const SizedBox(height: 32),
            Text(
              isCapable ? 'Power Up with On-Device AI' : 'Device Not Supported',
              style: context.typography.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              isCapable 
                ? 'ZapBook uses 100% private, on-device AI to supercharge your reading experience. No data ever leaves your device.'
                : 'Use ZapBook on a modern, more capable device to have access to AI features like summaries and smart quizzes.',
              style: context.typography.bodyL.copyWith(color: context.colors.slate),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (isCapable) ...[
              _FeatureRow(
                icon: LucideIcons.bookOpen,
                title: 'AI Book Summaries',
                description: 'Get concise summaries of chapters as you read.',
              ),
              const SizedBox(height: 16),
              _FeatureRow(
                icon: LucideIcons.brainCircuit,
                title: 'Smart Quizzes',
                description: 'Test your knowledge with AI-generated quizzes.',
              ),
            ],
            const Spacer(),
            if (isCapable) ...[
              AppButton(
                label: 'Download & Continue ($modelName)',
                icon: LucideIcons.download,
                fullWidth: true,
                onTap: () async {
                  final aiService = getIt<AiService>();
                  final url = _capability?.modelUrl;
                  final hash = _capability?.expectedHash;
                  if (url != null && hash != null) {
                    await aiService.startDownload(url, hash);
                  } else {
                    await aiService.skipSetup();
                  }
                  await _completeOnboarding();
                },
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Skip for Now',
                variant: AppButtonVariant.ghost,
                fullWidth: true,
                onTap: () async {
                  final aiService = getIt<AiService>();
                  await aiService.skipSetup();
                  await _completeOnboarding();
                },
              ),
            ] else ...[
              AppButton(
                label: 'Continue',
                fullWidth: true,
                onTap: () async {
                  final aiService = getIt<AiService>();
                  await aiService.skipSetup();
                  await _completeOnboarding();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.colors.plum.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: context.colors.plum, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.typography.bodyL.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(description, style: context.typography.bodyS.copyWith(color: context.colors.slate)),
            ],
          ),
        ),
      ],
    );
  }
}
