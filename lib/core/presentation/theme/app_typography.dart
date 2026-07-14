import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography extends ThemeExtension<AppTypography> {
  final TextStyle displayXl;
  final TextStyle displayL;
  final TextStyle displayM;
  final TextStyle h1;
  final TextStyle h2;
  final TextStyle h3;
  final TextStyle eyebrow;
  final TextStyle bodyL;
  final TextStyle body;
  final TextStyle bodyS;
  final TextStyle label;
  final TextStyle button;
  final TextStyle mono;
  final TextStyle caption;

  const AppTypography({
    required this.displayXl,
    required this.displayL,
    required this.displayM,
    required this.h1,
    required this.h2,
    required this.h3,
    required this.eyebrow,
    required this.bodyL,
    required this.body,
    required this.bodyS,
    required this.label,
    required this.button,
    required this.mono,
    required this.caption,
  });

  @override
  AppTypography copyWith({
    TextStyle? displayXl,
    TextStyle? displayL,
    TextStyle? displayM,
    TextStyle? h1,
    TextStyle? h2,
    TextStyle? h3,
    TextStyle? eyebrow,
    TextStyle? bodyL,
    TextStyle? body,
    TextStyle? bodyS,
    TextStyle? label,
    TextStyle? button,
    TextStyle? mono,
    TextStyle? caption,
  }) {
    return AppTypography(
      displayXl: displayXl ?? this.displayXl,
      displayL: displayL ?? this.displayL,
      displayM: displayM ?? this.displayM,
      h1: h1 ?? this.h1,
      h2: h2 ?? this.h2,
      h3: h3 ?? this.h3,
      eyebrow: eyebrow ?? this.eyebrow,
      bodyL: bodyL ?? this.bodyL,
      body: body ?? this.body,
      bodyS: bodyS ?? this.bodyS,
      label: label ?? this.label,
      button: button ?? this.button,
      mono: mono ?? this.mono,
      caption: caption ?? this.caption,
    );
  }

  @override
  AppTypography lerp(ThemeExtension<AppTypography>? other, double t) {
    if (other is! AppTypography) return this;
    return AppTypography(
      displayXl: TextStyle.lerp(displayXl, other.displayXl, t)!,
      displayL: TextStyle.lerp(displayL, other.displayL, t)!,
      displayM: TextStyle.lerp(displayM, other.displayM, t)!,
      h1: TextStyle.lerp(h1, other.h1, t)!,
      h2: TextStyle.lerp(h2, other.h2, t)!,
      h3: TextStyle.lerp(h3, other.h3, t)!,
      eyebrow: TextStyle.lerp(eyebrow, other.eyebrow, t)!,
      bodyL: TextStyle.lerp(bodyL, other.bodyL, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      bodyS: TextStyle.lerp(bodyS, other.bodyS, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      button: TextStyle.lerp(button, other.button, t)!,
      mono: TextStyle.lerp(mono, other.mono, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
    );
  }

  static final instance = AppTypography(
    displayXl: GoogleFonts.bricolageGrotesque(
      fontWeight: FontWeight.w600,
      fontSize: 64,
      height: 1.02,
      letterSpacing: -0.02 * 64,
    ),
    displayL: GoogleFonts.bricolageGrotesque(
      fontWeight: FontWeight.w600,
      fontSize: 48,
      height: 1.05,
      letterSpacing: -0.02 * 48,
    ),
    displayM: GoogleFonts.bricolageGrotesque(
      fontWeight: FontWeight.w600,
      fontSize: 36,
      height: 1.1,
      letterSpacing: -0.015 * 36,
    ),
    h1: GoogleFonts.bricolageGrotesque(
      fontWeight: FontWeight.w600,
      fontSize: 28,
      height: 1.18,
      letterSpacing: -0.015 * 28,
    ),
    h2: GoogleFonts.bricolageGrotesque(
      fontWeight: FontWeight.w600,
      fontSize: 22,
      height: 1.25,
      letterSpacing: -0.01 * 22,
    ),
    h3: GoogleFonts.bricolageGrotesque(
      fontWeight: FontWeight.w600,
      fontSize: 18,
      height: 1.3,
      letterSpacing: -0.005 * 18,
    ),
    eyebrow: GoogleFonts.hankenGrotesk(
      fontWeight: FontWeight.w600,
      fontSize: 12,
      height: 1.2,
      letterSpacing: 0.08 * 12,
    ),
    bodyL: GoogleFonts.hankenGrotesk(
      fontWeight: FontWeight.w400,
      fontSize: 17,
      height: 1.5,
    ),
    body: GoogleFonts.hankenGrotesk(
      fontWeight: FontWeight.w400,
      fontSize: 15,
      height: 1.5,
    ),
    bodyS: GoogleFonts.hankenGrotesk(
      fontWeight: FontWeight.w400,
      fontSize: 13,
      height: 1.45,
    ),
    label: GoogleFonts.hankenGrotesk(
      fontWeight: FontWeight.w500,
      fontSize: 13,
      height: 1.3,
    ),
    button: GoogleFonts.hankenGrotesk(
      fontWeight: FontWeight.w600,
      fontSize: 14,
      height: 1.0,
    ),
    mono: GoogleFonts.jetBrainsMono(
      fontWeight: FontWeight.w500,
      fontSize: 13,
      height: 1.4,
    ),
    caption: GoogleFonts.hankenGrotesk(
      fontWeight: FontWeight.w400,
      fontSize: 12,
      height: 1.4,
    ),
  );
}
