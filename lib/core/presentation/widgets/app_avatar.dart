import 'package:flutter/material.dart';
import 'package:zapbook/theme/app_theme.dart';

class AppAvatar extends StatelessWidget {
  final String emoji;
  final double size;
  final Color? ringColor;

  const AppAvatar({
    super.key,
    required this.emoji,
    this.size = 44.0,
    this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    final semanticColors = context.colors;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: semanticColors.mist,
        shape: BoxShape.circle,
        border: Border.all(color: ringColor ?? semanticColors.hairline2),
      ),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.5, height: 1.0)),
    );
  }
}
