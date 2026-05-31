import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:zapbook/widgets/app_sheet.dart';

@widgetbook.UseCase(name: 'Default', type: AppSheet)
Widget buildDefaultAppSheetUseCase(BuildContext context) {
  return const AppSheet(
    child: SizedBox(
      width: double.infinity,
      height: 200,
      child: Center(
        child: Text('Sheet Content'),
      ),
    ),
  );
}

