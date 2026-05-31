import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:zapbook/widgets/app_sats.dart';

@widgetbook.UseCase(
  name: 'Default',
  type: AppSats,
)
Widget buildAppSatsUseCase(BuildContext context) {
  return const Center(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppSats(amount: 2100),
        SizedBox(width: 12),
        AppSats(amount: 48250, size: 15),
      ],
    ),
  );
}
