import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/presentation/widgets/app_input.dart';
import 'package:zapbook/core/presentation/widgets/zap_sheet.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';

void main() {
  Widget createWidgetUnderTest(
    void Function(ZapGesture, int, String?) onZapSelected,
    GoRouter router,
  ) {
    return MaterialApp.router(theme: lightTheme, routerConfig: router);
  }

  GoRouter createRouter(void Function(ZapGesture, int, String?) onZapSelected) {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/sheet',
          builder: (context, state) => Scaffold(
            body: ZapSheet(
              header: const Text('Test Header'),
              onZapSelected: onZapSelected,
            ),
          ),
        ),
      ],
    );
  }

  testWidgets('renders ZapSheet with all fixed gestures', (tester) async {
    final router = createRouter((gesture, amount, message) {});
    await tester.pumpWidget(
      createWidgetUnderTest((gesture, amount, message) {}, router),
    );
    router.push('/sheet');
    await tester.pumpAndSettle();

    expect(find.text('Test Header'), findsOneWidget);

    for (final gesture in ZapGesture.values) {
      if (gesture != ZapGesture.gift) {
        expect(find.text(gesture.emoji), findsOneWidget);
      }
    }

    expect(find.text('Gift wrap'), findsOneWidget);
  });

  testWidgets('tapping fixed gesture calls onZapSelected', (tester) async {
    ZapGesture? selectedGesture;
    int? selectedAmount;
    String? selectedMessage;

    void onZapSelected(gesture, amount, message) {
      selectedGesture = gesture;
      selectedAmount = amount;
      selectedMessage = message;
    }

    final router = createRouter(onZapSelected);
    await tester.pumpWidget(createWidgetUnderTest(onZapSelected, router));
    router.push('/sheet');
    await tester.pumpAndSettle();

    await tester.tap(find.text('🚀')); // Rocket is 2100 sats
    await tester.pumpAndSettle();

    expect(selectedGesture, ZapGesture.rocket);
    expect(selectedAmount, 2100);
    expect(selectedMessage, isNull);
  });

  testWidgets('tapping gift wrap expands custom input and allows custom zap', (
    tester,
  ) async {
    ZapGesture? selectedGesture;
    int? selectedAmount;
    String? selectedMessage;

    void onZapSelected(gesture, amount, message) {
      selectedGesture = gesture;
      selectedAmount = amount;
      selectedMessage = message;
    }

    final router = createRouter(onZapSelected);
    await tester.pumpWidget(createWidgetUnderTest(onZapSelected, router));
    router.push('/sheet');
    await tester.pumpAndSettle();

    expect(find.byType(AppInput), findsNothing);

    // Tap the gift wrap container
    await tester.tap(find.text('Gift wrap'));
    await tester.pumpAndSettle();

    // Now inputs should be visible
    expect(find.byType(AppInput), findsNWidgets(2));
    expect(find.text('Enter custom amount'), findsOneWidget);
    expect(find.text('Leave a note'), findsOneWidget);
    expect(find.text('Send Zap'), findsOneWidget);

    // Enter amount and note
    await tester.enterText(
      find.widgetWithText(AppInput, 'Enter custom amount'),
      '5000',
    );
    await tester.enterText(
      find.widgetWithText(AppInput, 'Leave a note'),
      'Great work',
    );

    // Tap send zap
    await tester.tap(find.text('Send Zap'));
    await tester.pumpAndSettle();

    expect(selectedGesture, ZapGesture.gift);
    expect(selectedAmount, 5000);
    expect(selectedMessage, 'Great work');
  });

  testWidgets('does not call onZapSelected if custom amount is invalid', (
    tester,
  ) async {
    var called = false;

    void onZapSelected(gesture, amount, message) {
      called = true;
    }

    final router = createRouter(onZapSelected);
    await tester.pumpWidget(createWidgetUnderTest(onZapSelected, router));
    router.push('/sheet');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gift wrap'));
    await tester.pumpAndSettle();

    // Leave amount empty
    await tester.tap(find.text('Send Zap'));
    await tester.pumpAndSettle();

    expect(called, isFalse);

    // Enter invalid amount
    await tester.enterText(
      find.widgetWithText(AppInput, 'Enter custom amount'),
      '0',
    );
    await tester.tap(find.text('Send Zap'));
    await tester.pumpAndSettle();

    expect(called, isFalse);
  });
}
