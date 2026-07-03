import 'package:flutter/material.dart';

import 'package:zapbook/theme/app_theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final double padding;
  final double borderRadius;
  final Color? backgroundColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding = 18.0,
    this.borderRadius = 24.0,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final semanticColors = context.colors;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor ?? semanticColors.paper2,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: semanticColors.ink.withValues(alpha: 0.09)),
      ),
      child: child,
    );
  }
}
