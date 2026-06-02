import 'package:flutter/material.dart';
import 'package:zapbook/theme/app_theme.dart';

import 'package:zapbook/features/book_ingestion/presentation/widgets/reader/reader_body.dart';

class ReaderPullIndicator extends StatelessWidget {
  const ReaderPullIndicator({required this.pull, super.key});

  final ReaderPullState? pull;

  @override
  Widget build(BuildContext context) {
    final current = pull;
    final colors = context.colors;
    final typography = context.typography;
    final top = current?.edge == ReaderPullEdge.top;
    final isArmed = current?.armed ?? false;
    final progress = current?.progress ?? 0;
    final visible = current != null;

    return Align(
      alignment: top ? Alignment.topCenter : Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(
          top: top ? MediaQuery.of(context).padding.top + 16 : 0,
          bottom: top ? 0 : MediaQuery.of(context).padding.bottom + 20,
        ),
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
                      top
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: isArmed ? colors.paper : colors.ink,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _label(top: top, armed: isArmed),
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

  String _label({required bool top, required bool armed}) {
    if (top) return armed ? 'Release for previous' : 'Pull for previous';
    return armed ? 'Release for next' : 'Pull for next';
  }
}
