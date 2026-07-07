import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/features/book_ingestion/data/cover/canvas_cover_generator.dart';
import 'package:image/image.dart' as img;

void main() {
  group('CanvasCoverGenerator', () {
    test(
      'generates an abstract cover successfully when no source image is provided',
      () async {
        const generator = CanvasCoverGenerator(
          width: 100,
          height: 150,
          quality: 50,
        );
        final result = await generator.generate(title: 'Test Abstract Book');
        expect(result, isNotNull);
        expect(result.isNotEmpty, true);

        // Verify the generated result is a valid JPG
        final decodedImage = img.decodeJpg(result);
        expect(decodedImage, isNotNull);
        expect(decodedImage?.width, 100);
        expect(decodedImage?.height, 150);
      },
    );

    test('generates cover from source image if provided and valid', () async {
      // Create a simple valid 50x50 PNG using flutter test's utilities or image package
      final image = img.Image(width: 50, height: 50);
      img.fill(image, color: img.ColorRgb8(255, 0, 0)); // fill with red
      final sourceImageBytes = img.encodePng(image);

      const generator = CanvasCoverGenerator(
        width: 100,
        height: 150,
        quality: 50,
      );
      final result = await generator.generate(
        title: 'Test Image Book',
        sourceImage: sourceImageBytes,
      );

      expect(result, isNotNull);
      expect(result.isNotEmpty, true);

      // Verify the generated result is a valid JPG
      final decodedImage = img.decodeJpg(result);
      expect(decodedImage, isNotNull);
      expect(decodedImage?.width, 100);
      expect(decodedImage?.height, 150);
    });

    test(
      'falls back to abstract generation if source image is invalid',
      () async {
        // Provide an invalid byte array that cannot be decoded
        final invalidImageBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

        const generator = CanvasCoverGenerator(
          width: 100,
          height: 150,
          quality: 50,
        );
        final result = await generator.generate(
          title: 'Test Invalid Image Book',
          sourceImage: invalidImageBytes,
        );

        expect(result, isNotNull);
        expect(result.isNotEmpty, true);

        final decodedImage = img.decodeJpg(result);
        expect(decodedImage, isNotNull);
        expect(decodedImage?.width, 100);
        expect(decodedImage?.height, 150);
      },
    );
  });
}
