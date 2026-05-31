import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'package:zapbook/features/book_ingestion/data/cover/cover_generator.dart';

final class CanvasCoverGenerator implements CoverGenerator {
  const CanvasCoverGenerator({this.width = 600, this.height = 900});

  final int width;
  final int height;

  static const Color _mist = Color(0xFFEFE9DF);
  static const Color _ink = Color(0xFF1F1B16);
  static const Color _bitcoin = Color(0xFFF7931A);
  static const Color _plum = Color(0xFF6B4FC7);
  static const Color _mint = Color(0xFF3DCB89);
  static const Color _sky = Color(0xFF4F8EFF);
  static const Color _coral = Color(0xFFFF8062);
  static const Color _butter = Color(0xFFF7C948);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _black = Color(0xFF000000);

  @override
  Future<Uint8List> generate({
    required String title,
    Uint8List? sourceImage,
  }) async {
    ui.Image? illustration;
    if (sourceImage != null) {
      try {
        final codec = await ui.instantiateImageCodec(sourceImage);
        final frame = await codec.getNextFrame();
        illustration = frame.image;
      } on Exception {
        illustration = null;
      }
    }

    final data = await _renderCover(title, illustration);
    illustration?.dispose();
    return data;
  }

  Future<Uint8List> _renderCover(String title, ui.Image? illustration) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final bounds = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());

    canvas.drawRect(bounds, Paint()..color = _mist);

    final hueColor = _getHueForTitle(title);
    final spineWidth = math.max(6.0, width * 0.06);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, spineWidth, height.toDouble()),
      Paint()..color = hueColor,
    );

    canvas.saveLayer(bounds, Paint());

    if (illustration != null) {
      final src = Rect.fromLTWH(
        0,
        0,
        illustration.width.toDouble(),
        illustration.height.toDouble(),
      );
      final scaleX = width / illustration.width;
      final scaleY = height / illustration.height;
      final scale = math.max(scaleX, scaleY);
      final destWidth = illustration.width * scale;
      final destHeight = illustration.height * scale;
      final dest = Rect.fromLTWH(
        (width - destWidth) / 2,
        (height - destHeight) / 2,
        destWidth,
        destHeight,
      );
      canvas.drawImageRect(illustration, src, dest, Paint());
    } else {
      _drawAbstractArt(canvas, bounds, title);
    }

    final gradient = RadialGradient(
      center: Alignment.topRight,
      radius: 1.3,
      colors: [_white, _white.withValues(alpha: 0.0)],
      stops: const [0.3, 0.85],
    ).createShader(bounds);

    canvas.drawRect(
      bounds,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = gradient,
    );

    canvas.restore();

    final shadowGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        _black.withValues(alpha: 0.15),
        _black.withValues(alpha: 0.0),
        _black.withValues(alpha: 0.0),
        _black.withValues(alpha: 0.05),
      ],
      stops: const [0.0, 0.05, 0.95, 1.0],
    ).createShader(bounds);

    canvas.drawRect(bounds, Paint()..shader = shadowGradient);

    final titleSize = math.max(12.0, width * 0.13);
    final basePadding = math.max(8.0, width * 0.08);

    final titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: TextStyle(
          color: _ink,
          fontSize: titleSize,
          fontWeight: FontWeight.w700,
          height: 1.05,
          letterSpacing: -0.02 * titleSize,
          shadows: [
            Shadow(
              color: _black.withValues(alpha: 0.6),
              offset: const Offset(0, 1),
              blurRadius: 6.0,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    final maxTitleWidth = width - (spineWidth + basePadding * 2);
    titlePainter.layout(maxWidth: maxTitleWidth);

    final titleOffset = Offset(
      spineWidth + basePadding,
      height - basePadding - titlePainter.height,
    );

    titlePainter.paint(canvas, titleOffset);

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    if (data == null) {
      throw StateError('Failed to encode generated cover');
    }
    return data.buffer.asUint8List();
  }

  void _drawAbstractArt(Canvas canvas, Rect bounds, String title) {
    final seed = title.hashCode;
    final palette = [_bitcoin, _plum, _mint, _sky, _coral, _butter];
    final random = math.Random(seed);

    final blobCount = 20 + random.nextInt(11);
    for (var i = 0; i < blobCount; i++) {
      final color = palette[random.nextInt(palette.length)];

      final x = random.nextDouble() * bounds.width;
      final y = random.nextDouble() * bounds.height;
      final radius =
          (random.nextDouble() * bounds.width * 0.3) + bounds.width * 0.1;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = color.withValues(alpha: 0.7),
      );
    }
  }

  Color _getHueForTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('bitcoin')) return _bitcoin;
    if (lower.contains('nostr')) return _plum;
    final hash = title.hashCode;
    final hues = [_bitcoin, _plum, _mint, _sky];
    return hues[hash.abs() % hues.length];
  }
}
