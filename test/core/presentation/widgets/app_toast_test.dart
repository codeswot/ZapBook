import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/core/presentation/widgets/app_toast.dart';
import 'package:zapbook/theme/app_theme.dart';

void main() {
  Widget buildTestApp({required Widget child}) {
    return MaterialApp(
      theme: lightTheme,
      home: Scaffold(body: Builder(builder: (context) => child)),
    );
  }

  group('AppToast', () {
    testWidgets('shows simple snackbar toast', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  context.toast.show('Test message');
                },
                child: const Text('Show'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Test message'), findsOneWidget);
    });

    testWidgets('shows success snackbar toast', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  context.toast.showSuccess('Success message');
                },
                child: const Text('Show'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Success message'), findsOneWidget);
      expect(find.byIcon(LucideIcons.check), findsOneWidget);
    });

    testWidgets('shows error snackbar toast with action', (tester) async {
      bool actionCalled = false;
      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  context.toast.showError(
                    'Error message',
                    actionLabel: 'Retry',
                    onAction: () {
                      actionCalled = true;
                    },
                  );
                },
                child: const Text('Show'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Error message'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(actionCalled, isTrue);
    });

    testWidgets('shows info snackbar toast', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  context.toast.showInfo('Info message');
                },
                child: const Text('Show'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Info message'), findsOneWidget);
      expect(find.byIcon(LucideIcons.info), findsOneWidget);
    });

    testWidgets('shows warning snackbar toast', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  context.toast.showWarning('Warning message');
                },
                child: const Text('Show'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Warning message'), findsOneWidget);
      expect(find.byIcon(LucideIcons.zap), findsOneWidget);
    });

    testWidgets('shows root overlay toast', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  context.toast.show(
                    'Overlay message',
                    rootNavigator: true,
                    actionLabel: 'Close',
                    onAction: () {},
                  );
                },
                child: const Text('Show'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Overlay message'), findsOneWidget);

      // Tap to dismiss
      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pumpAndSettle();

      expect(find.text('Overlay message'), findsNothing);
    });
  });
}
