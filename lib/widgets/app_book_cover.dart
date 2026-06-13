import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/theme/app_radii.dart';

enum AppBookCoverHue { orange, purple, mint, sky }

class AppBookCover extends StatelessWidget {
  final double width;
  final double height;
  final AppBookCoverHue hue;
  final String? title;
  final String? author;
  final ImageProvider? image;

  const AppBookCover({
    super.key,
    this.width = 96,
    this.height = 132,
    this.hue = AppBookCoverHue.orange,
    this.title,
    this.author,
    this.image,
  });

  @override
  Widget build(BuildContext context) {
    final semanticColors = context.colors;
    final typography = context.typography;
    final cacheWidth = (width * MediaQuery.devicePixelRatioOf(context)).round();

    Color hueColor;
    switch (hue) {
      case AppBookCoverHue.purple:
        hueColor = semanticColors.plum;
        break;
      case AppBookCoverHue.mint:
        hueColor = semanticColors.mint;
        break;
      case AppBookCoverHue.sky:
        hueColor = semanticColors.sky;
        break;
      case AppBookCoverHue.orange:
        hueColor = semanticColors.bitcoin;
        break;
    }

    final spineWidth = math.max(6.0, width * 0.06);
    final titleSize = math.max(12.0, width * 0.13);
    final authorSize = math.max(9.0, width * 0.085);
    final basePadding = math.max(8.0, width * 0.08);

    final gradientRadius = 1.3;
    final solidStop = 0.3;
    final transparentStop = 0.85;

    final shadowAlphaStart = 0.15;
    final shadowAlphaEnd = 0.05;
    final shadowStopStart = 0.0;
    final shadowStopMidLeft = 0.05;
    final shadowStopMidRight = 0.95;
    final shadowStopEnd = 1.0;

    final textSpacing = 4.0;
    final textLineHeight = 1.05;
    final textLetterSpacing = -0.02 * titleSize;
    final authorLineHeight = 1.2;
    final textShadowAlpha = 0.6;
    final textShadowBlur = 6.0;
    final textShadowOffsetY = 1.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: semanticColors.mist,
        borderRadius: AppRadii.br12,
        border: Border.all(color: semanticColors.hairline2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (image != null)
            Positioned.fill(
              child: ShaderMask(
                shaderCallback: (rect) {
                  return RadialGradient(
                    center: Alignment.topRight,
                    radius: gradientRadius,
                    colors: [semanticColors.white, semanticColors.transparent],
                    stops: [solidStop, transparentStop],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: Image(
                  image: ResizeImage(image!, width: cacheWidth),
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stack) =>
                      title != null && title!.isNotEmpty
                      ? CustomPaint(
                          painter: _AbstractArtPainter(
                            title!.hashCode,
                            semanticColors,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            )
          else if (title != null && title!.isNotEmpty)
            Positioned.fill(
              child: ShaderMask(
                shaderCallback: (rect) {
                  return RadialGradient(
                    center: Alignment.topRight,
                    radius: gradientRadius,
                    colors: [semanticColors.white, semanticColors.transparent],
                    stops: [solidStop, transparentStop],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: CustomPaint(
                  painter: _AbstractArtPainter(title!.hashCode, semanticColors),
                ),
              ),
            ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: spineWidth,
            child: Container(color: hueColor),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    semanticColors.black.withValues(alpha: shadowAlphaStart),
                    semanticColors.transparent,
                    semanticColors.transparent,
                    semanticColors.black.withValues(alpha: shadowAlphaEnd),
                  ],
                  stops: [
                    shadowStopStart,
                    shadowStopMidLeft,
                    shadowStopMidRight,
                    shadowStopEnd,
                  ],
                ),
              ),
            ),
          ),
          if (title != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: EdgeInsets.only(
                  left: spineWidth + basePadding,
                  right: basePadding,
                  bottom: basePadding,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title!,
                      style: typography.displayM.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: titleSize,
                        height: textLineHeight,
                        letterSpacing: textLetterSpacing,
                        color: semanticColors.ink,
                        shadows: [
                          Shadow(
                            color: semanticColors.black.withValues(
                              alpha: textShadowAlpha,
                            ),
                            offset: Offset(0, textShadowOffsetY),
                            blurRadius: textShadowBlur,
                          ),
                        ],
                      ),
                    ),
                    if (author != null) ...[
                      SizedBox(height: textSpacing),
                      Text(
                        author!,
                        style: typography.body.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: authorSize,
                          height: authorLineHeight,
                          color: semanticColors.slate,
                          shadows: [
                            Shadow(
                              color: semanticColors.black.withValues(
                                alpha: textShadowAlpha,
                              ),
                              offset: Offset(0, textShadowOffsetY),
                              blurRadius: textShadowBlur,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AbstractArtPainter extends CustomPainter {
  _AbstractArtPainter(this.seed, this.colors);

  final int seed;
  final SemanticColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final palette = [
      colors.bitcoin,
      colors.plum,
      colors.mint,
      colors.sky,
      colors.coral,
      colors.butter,
    ];
    final random = math.Random(seed);

    final blobCount = 20 + random.nextInt(11);
    for (var i = 0; i < blobCount; i++) {
      final color = palette[random.nextInt(palette.length)];

      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius =
          (random.nextDouble() * size.width * 0.3) + size.width * 0.1;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = color.withValues(alpha: 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AbstractArtPainter oldDelegate) {
    return oldDelegate.seed != seed;
  }
}
