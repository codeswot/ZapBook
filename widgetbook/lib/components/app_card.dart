import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:zapbook/widgets/app_card.dart';

@widgetbook.UseCase(name: 'Default', type: AppCard)
Widget buildDefaultAppCardUseCase(BuildContext context) {
  return const AppCard(
    child: Text('This is a simple flat card without shadows.'),
  );
}

