import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/features/home/presentation/widgets/home_shimmer.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';

void main() {
  testWidgets('HomeShimmer renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: const Scaffold(body: HomeShimmer()),
      ),
    );

    // Initial pump
    expect(find.byType(HomeShimmer), findsOneWidget);

    // Let the animation run
    await tester.pump(const Duration(seconds: 2));

    // Verify it doesn't crash and paints
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
