import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/features/book_ingestion/data/cover/canvas_cover_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const generator = CanvasCoverGenerator(width: 60, height: 90);

  test('renders a title into valid PNG bytes', () async {
    final bytes = await generator.generate(title: 'A Tale of Pixels');

    expect(bytes, isNotEmpty);
    expect(bytes.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
  });

  test('re-encodes a provided source image to PNG', () async {
    final source = await generator.generate(title: 'Source');

    final result = await generator.generate(
      title: 'Ignored',
      sourceImage: source,
    );

    expect(result.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
  });
}
