import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:zapbook/widgets/app_banner.dart';

@widgetbook.UseCase(name: 'Info Banner', type: AppBanner)
Widget buildInfoBannerUseCase(BuildContext context) {
  return AppBanner(
    tone: AppBannerTone.info,
    title: 'Update Available',
    message: 'A new version of ZapBook is ready to install.',
    onClose: () {},
  );
}

