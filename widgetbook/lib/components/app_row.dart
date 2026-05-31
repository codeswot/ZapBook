import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:zapbook/widgets/app_row.dart';

@widgetbook.UseCase(name: 'Default', type: AppRow)
Widget buildDefaultAppRowUseCase(BuildContext context) {
  return AppRow(
    title: 'Account Settings',
    subtitle: 'Manage your profile and preferences',
    leading: const Icon(LucideIcons.user),
    trailing: const Icon(LucideIcons.chevronRight),
    onTap: () {},
  );
}

