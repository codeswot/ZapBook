import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:zapbook/widgets/app_celebration_card.dart';

@widgetbook.UseCase(name: 'Default', type: AppCelebrationCard)
Widget buildDefaultAppCelebrationCardUseCase(BuildContext context) {
  return const AppCelebrationCard(
    emoji: '🥳',
    name: 'Satoshi',
    action: 'zapped Hal Finney',
    time: '2h',
    book: 'The Book of Satoshi',
    score: '9.8',
  );
}

