import 'dart:io';
import 'dart:typed_data';
import 'package:zapbook/core/domain/entities/circle_book.dart';

abstract class BookIngestionRepository {
  Future<File?> pickBook();
  Future<Uint8List?> pickImage();
  Future<CircleBook?> findExistingBook(String hash);
}
