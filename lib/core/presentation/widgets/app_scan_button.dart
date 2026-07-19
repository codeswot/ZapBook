import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/core/presentation/widgets/app_square_icon_button.dart';
import 'package:zapbook/core/presentation/widgets/qr_scanner_sheet.dart';

class AppQrScanButton extends StatelessWidget {
  const AppQrScanButton({
    super.key,
    required this.onScan,
    this.title = 'Scan QR Code',
    this.instructions = 'Point your camera at an npub QR code',
  });

  final ValueChanged<String> onScan;
  final String title;
  final String instructions;

  @override
  Widget build(BuildContext context) {
    return AppSquareIconButton(
      icon: LucideIcons.qrCode,
      onTap: () async {
        final result = await QrScannerSheet.show(
          context,
          title: title,
          instructions: instructions,
        );
        if (result == null || result.isEmpty) return;
        onScan(result.trim());
      },
    );
  }
}
