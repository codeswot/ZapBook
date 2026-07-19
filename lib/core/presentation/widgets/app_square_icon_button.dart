import 'package:flutter/material.dart';
import 'package:zapbook/core/presentation/theme/app_radii.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/core/presentation/widgets/bouncing_interactive_widget.dart';

class AppSquareIconButton extends StatelessWidget {
  const AppSquareIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 50,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return BouncingInteractiveWidget(
      onTap: onTap,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: context.colors.paper2,
          borderRadius: AppRadii.br10,
          border: Border.all(color: context.colors.hairline),
        ),
        child: Icon(icon, color: context.colors.slate),
      ),
    );
  }
}
