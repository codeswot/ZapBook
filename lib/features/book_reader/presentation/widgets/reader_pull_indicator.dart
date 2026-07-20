import 'package:flutter/material.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';

import 'package:zapbook/features/book_reader/presentation/widgets/reader_body.dart';

class ReaderPullIndicator extends StatelessWidget {
  const ReaderPullIndicator({required this.pull, super.key});

  final ReaderPullState? pull;

  @override
  Widget build(BuildContext context) {
    final current = pull;
    final colors = context.colors;
    final typography = context.typography;
    final isArmed = current?.armed ?? false;
    final progress = current?.progress ?? 0;
    final visible = current != null;

    Alignment alignment = Alignment.topCenter;
    EdgeInsets padding = EdgeInsets.zero;
    bool isPrevious = true;
    IconData iconData = Icons.keyboard_arrow_up_rounded;

    if (current != null) {
      switch (current.edge) {
        case ReaderPullEdge.top:
          alignment = Alignment.topCenter;
          padding = EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
          );
          isPrevious = true;
          iconData = Icons.keyboard_arrow_up_rounded;
          break;
        case ReaderPullEdge.bottom:
          alignment = Alignment.bottomCenter;
          padding = EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 20,
          );
          isPrevious = false;
          iconData = Icons.keyboard_arrow_down_rounded;
          break;
        case ReaderPullEdge.left:
          alignment = Alignment.centerLeft;
          padding = const EdgeInsets.only(left: 16);
          isPrevious = true;
          iconData = Icons.keyboard_arrow_left_rounded;
          break;
        case ReaderPullEdge.right:
          alignment = Alignment.centerRight;
          padding = const EdgeInsets.only(right: 16);
          isPrevious = false;
          iconData = Icons.keyboard_arrow_right_rounded;
          break;
      }
    }

    return Align(
      alignment: alignment,
      child: Padding(
        padding: padding,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: visible ? 0.85 + (progress * 0.15) : 0.7,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 120),
            opacity: visible ? (0.4 + progress * 0.6).clamp(0.0, 1.0) : 0.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isArmed ? colors.bitcoin : colors.bgElev,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isArmed ? colors.bitcoin : colors.hairline,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 150),
                    turns: isArmed ? 0.5 : 0,
                    child: Icon(
                      iconData,
                      size: 18,
                      color: isArmed ? colors.paper : colors.ink,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _label(isPrevious: isPrevious, armed: isArmed),
                    style: typography.caption.copyWith(
                      color: isArmed ? colors.paper : colors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _label({required bool isPrevious, required bool armed}) {
    if (isPrevious) return armed ? 'Release for previous' : 'Pull for previous';
    return armed ? 'Release for next' : 'Pull for next';
  }
}
