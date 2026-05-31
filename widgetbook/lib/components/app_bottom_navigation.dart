import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:zapbook/widgets/app_bottom_navigation.dart';

@widgetbook.UseCase(
  name: 'Default',
  type: AppBottomNavigation,
)
Widget buildAppBottomNavigationUseCase(BuildContext context) {
  return const Scaffold(
    bottomNavigationBar: AppBottomNavigation(activeId: 'home'),
    body: Center(child: Text('Bottom Nav')),
  );
}
