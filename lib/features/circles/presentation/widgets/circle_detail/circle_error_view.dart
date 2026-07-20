import 'package:flutter/material.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/features/circles/presentation/widgets/circle_detail/circle_detail_top_bar.dart';

class CircleErrorView extends StatelessWidget {
  const CircleErrorView({
    super.key,
    required this.message,
    required this.circleBookId,
  });

  final String message;
  final String circleBookId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleDetailTopBar(
          readersCount: 0,
          circleBookId: circleBookId,
          circleDirId: "",
          bookTitle: 'Loading...',
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: context.typography.body.copyWith(
                  color: context.colors.slate,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
