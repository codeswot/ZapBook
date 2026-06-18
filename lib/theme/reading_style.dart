import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:zapbook/theme/semantic_colors.dart';

enum ReaderFont {
  sans('Sans', 'Hanken Grotesk'),
  serif('Serif', 'Newsreader');

  const ReaderFont(this.label, this.displayName);

  final String label;
  final String displayName;

  static ReaderFont fromName(String? name) =>
      values.firstWhere((f) => f.name == name, orElse: () => ReaderFont.sans);
}

class ReadingStyle {
  const ReadingStyle({
    required this.paragraph,
    required this.heading,
    required this.pullquote,
    required this.caption,
    required this.code,
    required this.paragraphSpacing,
    required this.firstLineIndent,
  });

  final TextStyle paragraph;
  final TextStyle heading;
  final TextStyle pullquote;
  final TextStyle caption;
  final TextStyle code;

  final double paragraphSpacing;

  final double firstLineIndent;

  static const double maxContentWidth = 680;

  static ReadingStyle of(
    ReaderFont font,
    SemanticColors colors, {
    double textScale = 1.0,
  }) {
    final ink = colors.ink;
    final body = font == ReaderFont.serif
        ? GoogleFonts.newsreader(
            fontSize: 19 * textScale,
            height: 1.62,
            letterSpacing: 0.1,
            color: ink,
          )
        : GoogleFonts.hankenGrotesk(
            fontSize: 18 * textScale,
            height: 1.6,
            letterSpacing: 0.1,
            color: ink,
          );

    final headingFont = font == ReaderFont.serif
        ? GoogleFonts.newsreader(
            fontWeight: FontWeight.w600,
            color: ink,
            height: 1.25,
          )
        : GoogleFonts.bricolageGrotesque(
            fontWeight: FontWeight.w600,
            color: ink,
            height: 1.25,
          );

    return ReadingStyle(
      paragraph: body,
      heading: headingFont,
      pullquote: body.copyWith(
        fontStyle: FontStyle.italic,
        color: colors.slate,
      ),
      caption: body.copyWith(fontSize: 14 * textScale, color: colors.slate),
      code: GoogleFonts.jetBrainsMono(
        fontSize: 14 * textScale,
        height: 1.5,
        color: ink,
      ),
      paragraphSpacing: 18,
      firstLineIndent: 0,
    );
  }
}
