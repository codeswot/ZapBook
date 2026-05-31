import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:zapbook/widgets/app_avatar.dart';

@widgetbook.UseCase(
  name: 'Default',
  type: AppAvatar,
)
Widget buildAppAvatarUseCase(BuildContext context) {
  return const Center(
    child: AppAvatar(emoji: '🤠'),
  );
}
