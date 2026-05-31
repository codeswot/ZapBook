import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:zapbook/widgets/app_input.dart';

@widgetbook.UseCase(name: 'Default', type: AppInput)
Widget buildDefaultAppInputUseCase(BuildContext context) {
  return const AppInput(
    icon: LucideIcons.search,
    label: 'Search',
    initialValue: 'ZapBook design',
    trailing: Icon(LucideIcons.xCircle, size: 16),
  );
}

