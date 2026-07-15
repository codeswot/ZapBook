import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/features/library/presentation/widgets/library_shimmer.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';

void main() {
  testWidgets('LibraryShimmer renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: const Scaffold(body: LibraryShimmer()),
      ),
    );

    // Initial pump
    expect(find.byType(LibraryShimmer), findsOneWidget);

    // Let the animation run
    await tester.pump(const Duration(seconds: 2));

    // Verify it doesn't crash and paints
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
