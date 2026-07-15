import 'dart:io';
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:injectable/injectable.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/core/services/circle_store_service.dart';
import 'package:zapbook/core/data/infrastructure/file_picker_service.dart';
import 'package:zapbook/features/library/domain/repositories/book_ingestion_repository.dart';

@Injectable(as: BookIngestionRepository)
class BookIngestionRepositoryImpl implements BookIngestionRepository {
  BookIngestionRepositoryImpl(
    this._filePickerService,
    this._circleStoreService,
  );

  final FilePickerService _filePickerService;
  final CircleStoreService _circleStoreService;

  @override
  Future<File?> pickBook() => _filePickerService.pickBook();

  @override
  Future<Uint8List?> pickImage() => _filePickerService.pickImage();

  @override
  Future<CircleBook?> findExistingBook(String hash) async {
    return _circleStoreService.currentCircles.firstWhereOrNull(
      (c) => c.contentHash == hash,
    );
  }
}
