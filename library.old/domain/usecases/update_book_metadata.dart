import 'dart:typed_data';

import 'package:injectable/injectable.dart';

import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/features/library/domain/repositories/library_repository.dart';

@injectable
final class UpdateBookMetadata {
  const UpdateBookMetadata(this._repository);

  final LibraryRepository _repository;

  Future<CircleBook> call(
    String id, {
    required String title,
    String? author,
    String? genre,
    Uint8List? coverImage,
  }) => _repository.updateBookMetadata(
    id,
    title: title,
    author: author,
    genre: genre,
    coverImage: coverImage,
  );
}
