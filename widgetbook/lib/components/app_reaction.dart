import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:zapbook/widgets/app_reaction.dart';

@widgetbook.UseCase(name: 'Default', type: AppReaction)
Widget buildDefaultAppReactionUseCase(BuildContext context) {
  return AppReaction(
    emoji: '🔥',
    label: 'Fire',
    sats: 21000,
    active: false,
    onTap: () {},
  );
}

@widgetbook.UseCase(name: 'Active', type: AppReaction)
Widget buildActiveAppReactionUseCase(BuildContext context) {
  return AppReaction(
    emoji: '⚡️',
    label: 'Zap',
    sats: 100000,
    active: true,
    onTap: () {},
  );
}

