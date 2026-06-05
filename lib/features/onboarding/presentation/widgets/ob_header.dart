import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/features/onboarding/presentation/widgets/ob_stepper.dart';

class ObHeader extends StatelessWidget {
  final int currentStep;
  final VoidCallback onBack;

  const ObHeader({
    super.key,
    required this.currentStep,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.colors.paper2,
                borderRadius: AppRadii.br999,
                border: Border.all(color: context.colors.hairline),
              ),
              child: Icon(
                LucideIcons.chevronLeft,
                size: 18,
                color: context.colors.slate,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: ObStepper(
              step: currentStep - 1,
              total: 4,
            ),
          ),
        ],
      ),
    );
  }
}
