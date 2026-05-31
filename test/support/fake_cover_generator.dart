import 'dart:typed_data';

import 'package:zapbook/features/book_ingestion/data/cover/cover_generator.dart';

final class FakeCoverGenerator implements CoverGenerator {
  const FakeCoverGenerator();

  static final Uint8List placeholder = Uint8List.fromList([
    8,
    6,
    7,
    5,
    3,
    0,
    9,
  ]);

  @override
  Future<Uint8List> generate({
    required String title,
    Uint8List? sourceImage,
  }) async {
    return sourceImage ?? placeholder;
  }
}
