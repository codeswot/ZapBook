import 'package:flutter/material.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class AppIconButton extends StatelessWidget {
  const AppIconButton({super.key, this.onTap, required this.icon});
  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return BouncingInteractiveWidget(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: context.colors.paper3,
          borderRadius: AppRadii.br10,
          border: Border.all(color: context.colors.hairline),
        ),
        child: Icon(icon, size: 14, color: context.colors.slate),
      ),
    );
  }
}
