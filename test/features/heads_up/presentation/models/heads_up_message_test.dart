import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/core/presentation/widgets/app_banner.dart';
import 'package:zapbook/core/presentation/widgets/bouncing_interactive_widget.dart';
import 'package:zapbook/features/heads_up/presentation/models/heads_up_message.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('HeadsUpMessage', () {
    test('props returns correct list', () {
      final child = Container();
      final msg = HeadsUpMessage(id: '1', child: child);
      expect(msg.props, ['1', child]);
    });

    testWidgets(
      'standard builds AppBanner with correct default properties for info',
      (tester) async {
        final msg = HeadsUpMessage.standard(
          id: '1',
          type: HeadsUpType.info,
          message: 'Info message',
          onDismiss: () {},
        );

        await tester.pumpWidget(buildApp(msg.child));

        expect(find.byType(AppBanner), findsOneWidget);
        expect(find.text('Info message'), findsOneWidget);
        expect(find.byIcon(LucideIcons.info), findsOneWidget); // Default icon
        expect(
          find.byIcon(LucideIcons.x),
          findsOneWidget,
        ); // Dismissible is true by default
        expect(find.byType(BouncingInteractiveWidget), findsOneWidget);
      },
    );

    testWidgets('standard builds correct properties for warning', (
      tester,
    ) async {
      final msg = HeadsUpMessage.standard(
        id: '1',
        type: HeadsUpType.warning,
        message: 'Warning',
      );

      await tester.pumpWidget(buildApp(msg.child));
      expect(find.byIcon(LucideIcons.alertTriangle), findsOneWidget);
    });

    testWidgets('standard builds correct properties for error', (tester) async {
      final msg = HeadsUpMessage.standard(
        id: '1',
        type: HeadsUpType.error,
        message: 'Error',
      );

      await tester.pumpWidget(buildApp(msg.child));
      expect(find.byIcon(LucideIcons.alertCircle), findsOneWidget);
    });

    testWidgets('standard builds correct properties for success', (
      tester,
    ) async {
      final msg = HeadsUpMessage.standard(
        id: '1',
        type: HeadsUpType.success,
        message: 'Success',
      );

      await tester.pumpWidget(buildApp(msg.child));
      expect(find.byIcon(LucideIcons.checkCircle), findsOneWidget);
    });

    testWidgets('standard allows custom leading and trailing', (tester) async {
      final msg = HeadsUpMessage.standard(
        id: '1',
        type: HeadsUpType.info,
        message: 'Custom',
        leading: const Icon(Icons.star),
        trailing: const Icon(Icons.ac_unit),
      );

      await tester.pumpWidget(buildApp(msg.child));
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.ac_unit), findsOneWidget);
      expect(
        find.byIcon(LucideIcons.x),
        findsNothing,
      ); // Overridden by trailing
    });

    testWidgets('standard handles non-dismissible', (tester) async {
      final msg = HeadsUpMessage.standard(
        id: '1',
        type: HeadsUpType.info,
        message: 'Cannot dismiss',
        dismissible: false,
      );

      await tester.pumpWidget(buildApp(msg.child));
      expect(find.byIcon(LucideIcons.x), findsNothing);
    });

    testWidgets('dismiss invokes callback', (tester) async {
      bool called = false;
      final msg = HeadsUpMessage.standard(
        id: '1',
        type: HeadsUpType.info,
        message: 'Tap me',
        onDismiss: () {
          called = true;
        },
      );

      await tester.pumpWidget(buildApp(msg.child));
      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });
  });
}
