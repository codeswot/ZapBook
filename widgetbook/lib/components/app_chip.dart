import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:zapbook/widgets/app_chip.dart';

@widgetbook.UseCase(name: 'Default', type: AppChip)
Widget buildDefaultAppChipUseCase(BuildContext context) {
  return AppChip(
    label: 'Default Chip',
    onTap: () {},
  );
}

@widgetbook.UseCase(name: 'Zap Tone (Selected)', type: AppChip)
Widget buildZapAppChipUseCase(BuildContext context) {
  return AppChip(
    label: 'Zap Chip',
    tone: AppChipTone.zap,
    selected: true,
    onTap: () {},
  );
}

