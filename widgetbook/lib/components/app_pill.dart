import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:zapbook/widgets/app_pill.dart';

@widgetbook.UseCase(name: 'Default', type: AppPill)
Widget buildDefaultAppPillUseCase(BuildContext context) {
  return const AppPill(
    emoji: '🎉',
    text: 'Celebration',
    count: 121,
  );
}

