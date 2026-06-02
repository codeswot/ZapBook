import 'package:flutter/material.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';

class ObBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color backgroundColor;
  final Color iconColor;
  final Color borderColor;

  const ObBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.backgroundColor,
    required this.iconColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadii.br14,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.typography.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.colors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: context.typography.bodyS.copyWith(
                    color: context.colors.slate,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
