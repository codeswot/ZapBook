import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/features/book_ingestion/presentation/widgets/zb_shimmer.dart';
import 'package:zapbook/theme/app_theme.dart';

void main() {
  testWidgets('renders the Zb status message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: const Scaffold(body: ZbShimmer()),
      ),
    );
    await tester.pump();

    expect(find.text('Zb is at it…'), findsOneWidget);
  });

  testWidgets('honours a custom message and line count', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: const Scaffold(
          body: ZbShimmer(message: 'Placing figures', lineCount: 2),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Placing figures'), findsOneWidget);
  });
}
