import 'package:flutter/material.dart';

import 'package:zapbook/theme/app_theme.dart';

class AppSheet extends StatelessWidget {
  final Widget child;

  const AppSheet({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final semanticColors = context.colors;
    final mediaQuery = MediaQuery.of(context);
    final maxHeight =
        (mediaQuery.size.height - mediaQuery.viewInsets.bottom) * 0.9;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: semanticColors.paper,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        border: Border(top: BorderSide(color: semanticColors.hairline)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: semanticColors.hairline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(child: child),
        ],
      ),
    );
  }
}
