import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/data/infrastructure/clipboard_service.dart';
import 'package:zapbook/features/profile/presentation/bloc/donate_cubit.dart';
import 'package:zapbook/features/profile/presentation/bloc/donate_state.dart';
import 'package:zapbook/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_donate_tile.dart';
import 'package:zapbook/features/profile/domain/entities/user_profile.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/core/presentation/widgets/zap_sheet.dart';
import 'package:go_router/go_router.dart';

class MockProfileCubit extends MockCubit<ProfileState>
    implements ProfileCubit {}

class MockDonateCubit extends MockCubit<DonateState> implements DonateCubit {}

class MockClipboardService extends Mock implements ClipboardService {}

void main() {
  late MockProfileCubit profileCubit;
  late MockDonateCubit donateCubit;
  late MockClipboardService clipboardService;

  setUpAll(() {
    registerFallbackValue(const ProfileLoading());
    registerFallbackValue(ZapGesture.thumbsUp);
  });

  setUp(() async {
    profileCubit = MockProfileCubit();
    donateCubit = MockDonateCubit();
    clipboardService = MockClipboardService();

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

    when(() => clipboardService.copy(any())).thenAnswer((_) async {});
    when(() => donateCubit.state).thenReturn(const DonateReady());

    await GetIt.I.reset();
    GetIt.I.registerSingleton<DonateCubit>(donateCubit);
    GetIt.I.registerSingleton<ClipboardService>(clipboardService);
  });

  tearDown(() async {
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
    when(() => donateCubit.sendGift(any(), any())).thenAnswer((_) async {
      when(() => donateCubit.state).thenReturn(const DonateSuccess('lnbc1...'));
    });

    await tester.pumpWidget(createWidgetUnderTest());

    // Open sheet
    await tester.tap(find.text('Support ZapBook'));
    await tester.pumpAndSettle();

    // Tap a gesture
    await tester.tap(find.text('🚀').first);
    await tester.pump();

    verify(() => donateCubit.sendGift(2100, 'ZapBook To the moon!')).called(1);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('zaps unsuccessfully copies invoice', (tester) async {
    when(() => donateCubit.sendGift(any(), any())).thenAnswer((_) async {
      when(() => donateCubit.state).thenReturn(
        const DonateFailure(
          showGift: false,
          userMessage: 'Could not open wallet. Invoice copied to clipboard.',
        ),
      );
    });

    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.text('Support ZapBook'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('🚀').first);
    await tester.pump();

    verify(() => donateCubit.sendGift(2100, 'ZapBook To the moon!')).called(1);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('copy recipient lightning address', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // 1. Tap the tile to open the sheet
    await tester.tap(find.text('Support ZapBook'));
    await tester.pumpAndSettle();

    // 2. Tap the copy button inside the sheet.
    // The sheet shows the recipient address, tapping it triggers the copy.
    await tester.tap(find.text('test@example.com').last);
    await tester.pump();

    verify(() => clipboardService.copy('test@example.com')).called(1);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
