import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/core/presentation/widgets/qr_scanner_sheet.dart';

class _FakeMobileScannerPlatform extends MobileScannerPlatform
    with MockPlatformInterfaceMixin {
  final _barcodesController = StreamController<BarcodeCapture?>.broadcast();

  @override
  Stream<BarcodeCapture?> get barcodesStream => _barcodesController.stream;

  @override
  Stream<TorchState> get torchStateStream => const Stream.empty();

  @override
  Stream<double> get zoomScaleStateStream => const Stream.empty();

  @override
  Widget buildCameraView() => const SizedBox();

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.off,
      size: Size(640, 480),
      numberOfCameras: 1,
      initialDeviceOrientation: DeviceOrientation.portraitUp,
    );
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> toggleTorch() async {}

  @override
  Future<void> dispose() async {}

  void emit(BarcodeCapture capture) => _barcodesController.add(capture);
}

void main() {
  late _FakeMobileScannerPlatform fakePlatform;

  setUp(() {
    MobileScannerController.resetPlatformSessionOwner();
    fakePlatform = _FakeMobileScannerPlatform();
    MobileScannerPlatform.instance = fakePlatform;
  });

  Widget buildTestWidget(Future<void> Function(BuildContext) onPressed) {
    return MaterialApp(
      theme: lightTheme,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => onPressed(context),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  testWidgets('renders title and instructions', (tester) async {
    await tester.pumpWidget(
      buildTestWidget((context) => QrScannerSheet.show(context)),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Scan QR Code'), findsOneWidget);
    expect(find.text('Point your camera at an npub QR code'), findsOneWidget);
  });

  testWidgets('renders torch toggle button', (tester) async {
    await tester.pumpWidget(
      buildTestWidget((context) => QrScannerSheet.show(context)),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byIcon(LucideIcons.zap), findsOneWidget);
  });

  testWidgets('dismissing the sheet pops with null', (tester) async {
    String? result = 'unset';

    await tester.pumpWidget(
      buildTestWidget((context) async {
        result = await QrScannerSheet.show(context);
      }),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });

  testWidgets('detecting a barcode pops with its rawValue', (tester) async {
    String? result = 'unset';

    await tester.pumpWidget(
      buildTestWidget((context) async {
        result = await QrScannerSheet.show(context);
      }),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    fakePlatform.emit(
      const BarcodeCapture(barcodes: [Barcode(rawValue: 'npub1testvalue')]),
    );
    await tester.pumpAndSettle();

    expect(result, 'npub1testvalue');
  });
}
