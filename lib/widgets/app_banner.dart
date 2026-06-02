import 'package:flutter/material.dart';

class AppBanner extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? trailing;
  final Color backgroundColor;

  const AppBanner({
    super.key,
    this.leading,
    required this.title,
    this.trailing,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 8,
        bottom: 8,
        left: 16,
        right: 16,
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(child: title),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}
