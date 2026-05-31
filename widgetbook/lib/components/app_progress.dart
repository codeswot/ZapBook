import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:zapbook/widgets/app_progress.dart';

@widgetbook.UseCase(name: 'Default', type: AppProgress)
Widget buildDefaultAppProgressUseCase(BuildContext context) {
  return const AppProgress(value: 0.65);
}

