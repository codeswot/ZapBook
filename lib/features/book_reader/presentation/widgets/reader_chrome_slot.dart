import 'package:flutter/material.dart';

class ReaderChromeSlot extends StatelessWidget {
  const ReaderChromeSlot({
    super.key,
    required this.alignment,
    required this.visible,
    required this.fromTop,
    required this.child,
  });

  final Alignment alignment;
  final bool visible;
  final bool fromTop;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        offset: visible ? Offset.zero : Offset(0, fromTop ? -1 : 1),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: visible ? 1 : 0,
          child: IgnorePointer(ignoring: !visible, child: child),
        ),
      ),
    );
  }
}
