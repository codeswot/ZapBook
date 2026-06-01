import 'package:flutter/material.dart';
import 'package:zapbook/theme/app_theme.dart';

class ReaderProgress extends StatelessWidget {
  const ReaderProgress({required this.value, super.key});

  final double value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final clamped = value.clamp(0.0, 1.0);
    final percent = (clamped * 100).round();

    return Row(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const knob = 12.0;
              final travel = (constraints.maxWidth - knob).clamp(
                0.0,
                double.infinity,
              );
              return SizedBox(
                height: knob,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.paper4,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: clamped,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.bitcoin,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Positioned(
                      left: travel * clamped,
                      child: Container(
                        width: knob,
                        height: knob,
                        decoration: BoxDecoration(
                          color: colors.bitcoin,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.paper, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$percent%',
          style: typography.caption.copyWith(
            color: colors.ink,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
