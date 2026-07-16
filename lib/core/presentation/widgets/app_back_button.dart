import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/core/presentation/widgets/app_icon_button.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed, this.size = 23, this.color});
  final VoidCallback? onPressed;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Back',
      child: AppIconButton(
        icon: Platform.isAndroid
            ? LucideIcons.arrowLeft
            : LucideIcons.chevronLeft,

        color: color,
        onTap: onPressed ?? () => context.pop(),
        size: size,
      ),
    );
  }
}
