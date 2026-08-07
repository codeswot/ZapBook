import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:zapbook/core/presentation/theme/app_radii.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';

class AppQrCode extends StatelessWidget {
  const AppQrCode({super.key, required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.white,
          borderRadius: AppRadii.br24,
          border: Border.all(color: colors.hairline),
        ),
        child: QrImageView(
          data: data,
          backgroundColor: colors.white,
          gapless: false,
          errorCorrectionLevel: QrErrorCorrectLevel.H,
          eyeStyle: QrEyeStyle(
            eyeShape: QrEyeShape.circle,
            color: colors.nostr,
          ),
          dataModuleStyle: QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.circle,
            color: colors.black,
          ),
        ),
      ),
    );
  }
}
