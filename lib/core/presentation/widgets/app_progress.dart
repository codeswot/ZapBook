import 'package:flutter/material.dart';
import 'package:zapbook/theme/app_radii.dart';

import 'package:zapbook/theme/app_theme.dart';

class AppProgress extends StatelessWidget {
  final double value;

  const AppProgress({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final semanticColors = context.colors;

    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: semanticColors.paper4,
        borderRadius: AppRadii.br999,
      ),
      child: ClipRRect(
        borderRadius: AppRadii.br999,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(color: semanticColors.bitcoin),
        ),
      ),
    );
  }
}
