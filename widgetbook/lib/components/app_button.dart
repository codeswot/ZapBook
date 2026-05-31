import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:zapbook/widgets/app_button.dart';

@widgetbook.UseCase(name: 'Primary', type: AppButton)
Widget buildPrimaryAppButtonUseCase(BuildContext context) {
  return AppButton(
    label: 'Primary',
    variant: AppButtonVariant.primary,
    onTap: () {},
  );
}

@widgetbook.UseCase(name: 'Purple', type: AppButton)
Widget buildPurpleAppButtonUseCase(BuildContext context) {
  return AppButton(
    label: 'Purple',
    variant: AppButtonVariant.purple,
    onTap: () {},
  );
}

@widgetbook.UseCase(name: 'Tonal', type: AppButton)
Widget buildTonalAppButtonUseCase(BuildContext context) {
  return AppButton(
    label: 'Tonal',
    variant: AppButtonVariant.tonal,
    onTap: () {},
  );
}

