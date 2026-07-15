import 'dart:io';
import 'dart:typed_data';
import 'package:injectable/injectable.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/features/library/domain/repositories/book_ingestion_repository.dart';

@injectable
class PickBookFileUseCase {
  const PickBookFileUseCase(this._repository);

  final BookIngestionRepository _repository;

  Future<File?> call() => _repository.pickBook();
}

@injectable
class PickCoverImageUseCase {
  const PickCoverImageUseCase(this._repository);

  final BookIngestionRepository _repository;

  Future<Uint8List?> call() => _repository.pickImage();
}

@injectable
class FindExistingBookUseCase {
  const FindExistingBookUseCase(this._repository);

  final BookIngestionRepository _repository;

  Future<CircleBook?> call(String hash) => _repository.findExistingBook(hash);
}
