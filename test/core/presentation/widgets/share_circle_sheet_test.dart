import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/features/circles/presentation/bloc/share_circle_cubit.dart';
import 'package:zapbook/features/circles/presentation/bloc/share_circle_state.dart';
import 'package:zapbook/core/presentation/widgets/share_circle_sheet.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/zbf/enums/book_source_format.dart';

class MockShareCircleCubit extends Mock implements ShareCircleCubit {}

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
  late MockShareCircleCubit shareCircleCubit;

  final testBook = CircleBook(
    id: 'b1',
    nostrGroudId: 'g1',
    circleDirId: 'd1',
    title: 'Test Book',
    author: 'Author',
    sourceFormat: BookSourceFormat.epub,
    pageCount: 10,
    chapterCount: 2,
    zbfPath: 'path/to/zbf',
    needsAiProcessing: false,
    zbfVersion: '1',
    createdAt: DateTime.now(),
    addedAt: DateTime.now(),
  );

  late _FakeMobileScannerPlatform fakeScannerPlatform;

  setUp(() async {
    await getIt.reset();
    shareCircleCubit = MockShareCircleCubit();
    getIt.registerSingleton<ShareCircleCubit>(shareCircleCubit);

    when(() => shareCircleCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => shareCircleCubit.load(any())).thenAnswer((_) async {});
    when(() => shareCircleCubit.isValidNpub(any())).thenReturn(true);
    when(() => shareCircleCubit.addNpub(any())).thenAnswer((_) async {});
    when(() => shareCircleCubit.close()).thenAnswer((_) async {});

    MobileScannerController.resetPlatformSessionOwner();
    fakeScannerPlatform = _FakeMobileScannerPlatform();
    MobileScannerPlatform.instance = fakeScannerPlatform;
  });

  Widget buildTestWidget() {
    return MaterialApp(
      theme: lightTheme,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ShareCircleSheet.show(context, testBook),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  group('ShareCircleSheet', () {
    testWidgets('renders loading state', (tester) async {
      when(() => shareCircleCubit.state).thenReturn(const ShareCircleLoading());

      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pump();

      expect(find.byType(ShareCircleSheet), findsOneWidget);
    });

    testWidgets('renders loaded state with friends', (tester) async {
      final contact = Contact(
        npub: 'npub1test12345678901234567890123456789012345678901234567890',
        displayName: 'Bob',
      );

      when(() => shareCircleCubit.state).thenReturn(
        ShareCircleLoaded(
          friends: [contact],
          selectedNpubs: [],
          existingMembers: {},
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('renders empty friends state', (tester) async {
      when(() => shareCircleCubit.state).thenReturn(
        const ShareCircleLoaded(
          friends: [],
          selectedNpubs: [],
          existingMembers: {},
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        find.text('No contacts yet. Paste an npub to add your first friend.'),
        findsOneWidget,
      );
    });

    testWidgets('renders a scan button next to the paste button', (
      tester,
    ) async {
      when(() => shareCircleCubit.state).thenReturn(
        const ShareCircleLoaded(
          friends: [],
          selectedNpubs: [],
          existingMembers: {},
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.qrCode), findsOneWidget);
    });

    testWidgets('scanning a valid npub calls cubit.addNpub', (tester) async {
      when(() => shareCircleCubit.state).thenReturn(
        const ShareCircleLoaded(
          friends: [],
          selectedNpubs: [],
          existingMembers: {},
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.qrCode));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      fakeScannerPlatform.emit(
        const BarcodeCapture(
          barcodes: [
            Barcode(
              rawValue:
                  'npub1v4v5td3r04f3n6udfqqv7eulx328y83tndq889yey8n3cnhrntsq8v0wps',
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      verify(
        () => shareCircleCubit.addNpub(
          'npub1v4v5td3r04f3n6udfqqv7eulx328y83tndq889yey8n3cnhrntsq8v0wps',
        ),
      ).called(1);
    });
  });
}
