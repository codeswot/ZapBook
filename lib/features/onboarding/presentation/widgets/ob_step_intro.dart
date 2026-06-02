import 'package:flutter/material.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/theme/app_radii.dart';

class ObStepIntro extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final Color accentDim;
  final Color accentLine;
  final String over;
  final String title;
  final String description;

  const ObStepIntro({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.accentDim,
    required this.accentLine,
    required this.over,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: accentDim,
            borderRadius: AppRadii.br24,
            border: Border.all(color: accentLine),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: accentColor, size: 36),
        ),
        const SizedBox(height: 24),
        Text(
          over,
          style: context.typography.bodyS.copyWith(
            fontWeight: FontWeight.w700,
            color: accentColor,
            letterSpacing: 0.13,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: context.typography.displayM.copyWith(
            fontWeight: FontWeight.w700,
            color: context.colors.ink,
            letterSpacing: -0.025,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          description,
          style: context.typography.bodyL.copyWith(color: context.colors.slate),
        ),
      ],
    );
  }
}
