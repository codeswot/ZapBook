import 'package:flutter/material.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/theme/app_radii.dart';

class ObStepper extends StatelessWidget {
  final int step;
  final int total;

  const ObStepper({super.key, required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    final orange = context.colors.bitcoin;
    final orangeDim = context.colors.bitcoinTint2;
    final s3 = context.colors.paper3;

    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(total, (i) {
              final active = i == step;
              final completed = i < step;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 6,
                  decoration: BoxDecoration(
                    color: completed ? orange : (active ? orangeDim : s3),
                    borderRadius: AppRadii.br999,
                    border: Border.all(
                      color: active ? orange : Colors.transparent,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          "${step + 1} of $total",
          style: context.typography.mono.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
            color: context.colors.slate,
          ),
        ),
      ],
    );
  }
}
