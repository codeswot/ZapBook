import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:zapbook/core/presentation/theme/app_radii.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/core/presentation/widgets/app_button.dart';
import 'package:zapbook/core/presentation/widgets/app_sheet.dart';
import 'package:zapbook/core/presentation/widgets/app_square_icon_button.dart';

class QrScannerSheet extends StatefulWidget {
  const QrScannerSheet({
    super.key,
    this.title = 'Scan QR Code',
    this.instructions = 'Point your camera at an npub QR code',
  });

  final String title;
  final String instructions;

  static Future<String?> show(
    BuildContext context, {
    String title = 'Scan QR Code',
    String instructions = 'Point your camera at an npub QR code',
  }) {
    return showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: context.colors.transparent,
      builder: (_) => QrScannerSheet(title: title, instructions: instructions),
    );
  }

  @override
  State<QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<QrScannerSheet>
    with WidgetsBindingObserver {
  final _controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_controller.start());
    } else {
      unawaited(_controller.stop());
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled || capture.barcodes.isEmpty) return;
    final value = capture.barcodes.first.rawValue;
    if (value == null || value.isEmpty) return;
    _handled = true;
    context.pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return AppSheet(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: typography.displayM.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.instructions,
              style: typography.body.copyWith(color: colors.slate),
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 24),
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.paper2,
                  borderRadius: AppRadii.br24,
                  border: Border.all(color: colors.hairline),
                ),
                child: ClipRRect(
                  borderRadius: AppRadii.br24,
                  child: MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                    placeholderBuilder: (context) =>
                        const _ScannerPlaceholder(),
                    errorBuilder: (context, error) =>
                        _ScannerError(error: error),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            AppSquareIconButton(
              icon: LucideIcons.zap,
              onTap: () => unawaited(_controller.toggleTorch()),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ScannerPlaceholder extends StatelessWidget {
  const _ScannerPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ColoredBox(
      color: colors.paper2,
      child: Center(
        child: Icon(LucideIcons.camera, color: colors.slate, size: 40),
      ),
    );
  }
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final isPermissionDenied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    final message = isPermissionDenied
        ? 'Camera permission denied. Enable camera access in your device settings to scan QR codes.'
        : error.errorCode.message;

    return ColoredBox(
      color: colors.paper2,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.cameraOff, color: colors.slate, size: 40),
              const SizedBox(height: 16),
              Text(
                message,
                style: typography.body.copyWith(color: colors.slate),
                textAlign: TextAlign.center,
              ),
              if (isPermissionDenied) ...[
                const SizedBox(height: 20),
                AppButton(
                  label: 'Open Settings',
                  icon: LucideIcons.settings,
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.sm,
                  onTap: () => unawaited(
                    AppSettings.openAppSettings(type: AppSettingsType.settings),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
