import 'package:flutter/material.dart';

import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';

class CircleProgressBar extends StatelessWidget {
  const CircleProgressBar({
    super.key,
    required this.value,
    required this.color,
  });

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: AppRadii.br999,
      child: Stack(
        children: [
          Container(height: 6, color: colors.hairline2),
          FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(height: 6, color: color),
          ),
        ],
      ),
    );
  }
}
