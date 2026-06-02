import 'package:flutter/material.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_banner.dart';

class AiVerifyingBanner extends StatelessWidget {
  const AiVerifyingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBanner(
      backgroundColor: context.colors.mintTint.withValues(alpha: 0.2),
      leading: SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: context.colors.mint2,
        ),
      ),
      title: Text(
        'Verifying AI Model hash...',
        style: context.typography.bodyS.copyWith(
          color: context.colors.mint2,
        ),
      ),
    );
  }
}
