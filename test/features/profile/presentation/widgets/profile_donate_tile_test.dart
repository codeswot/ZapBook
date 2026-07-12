import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/services/zap_service.dart';
import 'package:zapbook/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_donate_tile.dart';
import 'package:zapbook/features/profile/domain/entities/user_profile.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/core/presentation/widgets/zap_sheet.dart';
import 'package:go_router/go_router.dart';

class MockProfileCubit extends MockCubit<ProfileState>
    implements ProfileCubit {}

class MockZapService extends Mock implements ZapService {}

void main() {
  late MockProfileCubit profileCubit;
  late MockZapService zapService;

  setUpAll(() {
    registerFallbackValue(const ProfileLoading());
    registerFallbackValue(ZapGesture.thumbsUp);
  });

  setUp(() async {
    profileCubit = MockProfileCubit();
    zapService = MockZapService();

    when(() => profileCubit.donationRecipient).thenReturn('test@example.com');
    when(() => profileCubit.isNwcConnected).thenReturn(false);
    when(() => profileCubit.supportPercentOptions).thenReturn([0, 1, 3, 5, 10]);
    when(() => profileCubit.supportPercent).thenReturn(0);
    when(() => profileCubit.state).thenReturn(
      const ProfileLoaded(
        UserProfile(
          npub: 'npub',
          displayName: 'Test',
          picture: '',
          lightningAddress: 'profile@example.com',
          satsEarned: 0,
          dayStreak: 0,
          booksRead: 0,
          milestones: 0,
        ),
      ),
    );

    await GetIt.I.reset();
    GetIt.I.registerSingleton<ZapService>(zapService);

    String? clipboardText;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            clipboardText = methodCall.arguments['text'];
            return null;
          }
          if (methodCall.method == 'Clipboard.getData') {
            return {'text': clipboardText ?? 'test@example.com'};
          }
          return null;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    await GetIt.I.reset();
  });

  Widget createWidgetUnderTest() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: BlocProvider<ProfileCubit>.value(
              value: profileCubit,
              child: const ProfileDonateTile(),
            ),
          ),
        ),
      ],
    );

    return MaterialApp.router(theme: lightTheme, routerConfig: router);
  }

  testWidgets('renders correctly with NWC disconnected', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Support ZapBook'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.text('Auto donation zaps'), findsNothing);
  });

  testWidgets('renders Auto donation zaps when NWC is connected', (
    tester,
  ) async {
    when(() => profileCubit.isNwcConnected).thenReturn(true);
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.text('Support ZapBook'));
    await tester.pumpAndSettle();

    expect(find.text('Auto donation zaps').first, findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('slider interacts and sets support percent', (tester) async {
    when(() => profileCubit.isNwcConnected).thenReturn(true);
    when(() => profileCubit.setSupportPercent(any())).thenAnswer((_) async {});

    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.text('Support ZapBook'));
    await tester.pumpAndSettle();

    final slider = find.byType(Slider);
    await tester.drag(slider, const Offset(50, 0));
    await tester.pumpAndSettle();

    verify(() => profileCubit.setSupportPercent(any())).called(greaterThan(0));
  });

  testWidgets('tapping tile shows ZapSheet', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.text('Support ZapBook'));
    await tester.pumpAndSettle();

    expect(find.byType(ZapSheet), findsWidgets);
    expect(find.text('test@example.com'), findsWidgets);
  });

  testWidgets('zaps successfully through ZapSheet', (tester) async {
    when(
      () => zapService.donate(
        amountSats: any(named: 'amountSats'),
        comment: any(named: 'comment'),
      ),
    ).thenAnswer(
      (_) async => const ZapResult(
        invoice: 'lnbc1...',
        zapRequestId: 'zapRequestId',
        amountSats: 2100,
        gesture: ZapGesture.rocket,
        recipientPubkey: 'recipient',
        targetEventId: 'event',
      ),
    );
    when(
      () => zapService.payWithFallback('lnbc1...'),
    ).thenAnswer((_) async => true);

    await tester.pumpWidget(createWidgetUnderTest());

    // Open sheet
    await tester.tap(find.text('Support ZapBook'));
    await tester.pumpAndSettle();

    // Tap a gesture
    await tester.tap(find.text('🚀').first);
    await tester.pump();

    verify(
      () =>
          zapService.donate(amountSats: 2100, comment: 'ZapBook To the moon!'),
    ).called(1);
    verify(() => zapService.payWithFallback('lnbc1...')).called(1);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('zaps unsuccessfully copies invoice', (tester) async {
    when(
      () => zapService.donate(
        amountSats: any(named: 'amountSats'),
        comment: any(named: 'comment'),
      ),
    ).thenAnswer(
      (_) async => const ZapResult(
        invoice: 'lnbc1...',
        zapRequestId: 'zapRequestId',
        amountSats: 2100,
        gesture: ZapGesture.rocket,
        recipientPubkey: 'recipient',
        targetEventId: 'event',
      ),
    );
    when(
      () => zapService.payWithFallback('lnbc1...'),
    ).thenAnswer((_) async => false);

    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.text('Support ZapBook'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('🚀').first);
    await tester.pump();

    verify(
      () =>
          zapService.donate(amountSats: 2100, comment: 'ZapBook To the moon!'),
    ).called(1);
    verify(() => zapService.payWithFallback('lnbc1...')).called(1);

    // Clipboard should contain invoice
    final clipboardData = await Clipboard.getData('text/plain');
    expect(clipboardData?.text, 'lnbc1...');

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('copy recipient lightning address', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.text('test@example.com').first);
    await tester.pump();

    final clipboardData = await Clipboard.getData('text/plain');
    expect(clipboardData?.text, 'test@example.com');

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
