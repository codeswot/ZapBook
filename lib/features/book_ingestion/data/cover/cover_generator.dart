import 'dart:typed_data';

abstract interface class CoverGenerator {
  Future<Uint8List> generate({required String title, Uint8List? sourceImage});
}
