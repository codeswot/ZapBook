import 'package:flutter/material.dart';
import 'package:zapbook/theme/semantic_colors.dart';
import 'package:zapbook/theme/app_typography.dart';

export 'semantic_colors.dart';
export 'app_typography.dart';

final lightTheme = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: SemanticColors.light.plum,
    onPrimary: SemanticColors.light.bgElev,
    secondary: SemanticColors.light.bitcoin,
    onSecondary: SemanticColors.light.paper,
    surface: SemanticColors.light.paper,
    onSurface: SemanticColors.light.ink,
    error: SemanticColors.light.tomato,
  ),
  scaffoldBackgroundColor: SemanticColors.light.paper,
  textTheme: TextTheme(
    displayLarge: AppTypography.instance.displayXl,
    displayMedium: AppTypography.instance.displayL,
    displaySmall: AppTypography.instance.displayM,
    headlineLarge: AppTypography.instance.h1,
    headlineMedium: AppTypography.instance.h2,
    headlineSmall: AppTypography.instance.h3,
    bodyLarge: AppTypography.instance.bodyL,
    bodyMedium: AppTypography.instance.body,
    bodySmall: AppTypography.instance.bodyS,
    labelLarge: AppTypography.instance.label,
    labelSmall: AppTypography.instance.caption,
  ),
  extensions: [SemanticColors.light, AppTypography.instance],
);

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  colorScheme: ColorScheme.dark(
    primary: SemanticColors.dark.plum,
    onPrimary: SemanticColors.dark.bgElev,
    secondary: SemanticColors.dark.bitcoin,
    onSecondary: SemanticColors.dark.paper,
    surface: SemanticColors.dark.paper,
    onSurface: SemanticColors.dark.ink,
    error: SemanticColors.dark.tomato,
  ),
  scaffoldBackgroundColor: SemanticColors.dark.paper,
  textTheme: TextTheme(
    displayLarge: AppTypography.instance.displayXl.copyWith(
      color: SemanticColors.dark.ink,
    ),
    displayMedium: AppTypography.instance.displayL.copyWith(
      color: SemanticColors.dark.ink,
    ),
    displaySmall: AppTypography.instance.displayM.copyWith(
      color: SemanticColors.dark.ink,
    ),
    headlineLarge: AppTypography.instance.h1.copyWith(
      color: SemanticColors.dark.ink,
    ),
    headlineMedium: AppTypography.instance.h2.copyWith(
      color: SemanticColors.dark.ink,
    ),
    headlineSmall: AppTypography.instance.h3.copyWith(
      color: SemanticColors.dark.ink,
    ),
    bodyLarge: AppTypography.instance.bodyL.copyWith(
      color: SemanticColors.dark.ink,
    ),
    bodyMedium: AppTypography.instance.body.copyWith(
      color: SemanticColors.dark.ink,
    ),
    bodySmall: AppTypography.instance.bodyS.copyWith(
      color: SemanticColors.dark.slate,
    ),
    labelLarge: AppTypography.instance.label.copyWith(
      color: SemanticColors.dark.slate,
    ),
    labelSmall: AppTypography.instance.caption.copyWith(
      color: SemanticColors.dark.slate2,
    ),
  ),
  extensions: [SemanticColors.dark, AppTypography.instance],
);

extension ThemeContextExtension on BuildContext {
  SemanticColors get colors =>
      Theme.of(this).extension<SemanticColors>() ?? SemanticColors.light;
  AppTypography get typography =>
      Theme.of(this).extension<AppTypography>() ?? AppTypography.instance;
}
