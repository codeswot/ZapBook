import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('lightTheme has correct base properties', () {
    expect(lightTheme.brightness, Brightness.light);
    expect(lightTheme.useMaterial3, isTrue);
    expect(lightTheme.colorScheme.primary, SemanticColors.light.plum);
    expect(lightTheme.scaffoldBackgroundColor, SemanticColors.light.paper);
    expect(lightTheme.textTheme.displayLarge, isNotNull);
    expect(lightTheme.extensions, isNotEmpty);
  });

  test('darkTheme has correct base properties', () {
    expect(darkTheme.brightness, Brightness.dark);
    expect(darkTheme.useMaterial3, isTrue);
    expect(darkTheme.colorScheme.primary, SemanticColors.dark.plum);
    expect(darkTheme.scaffoldBackgroundColor, SemanticColors.dark.paper);

    // Test the text theme properties with dark ink overrides
    expect(darkTheme.textTheme.displayLarge, isNotNull);
    expect(darkTheme.extensions, isNotEmpty);
  });
}
