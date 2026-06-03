import 'dart:typed_data';

import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/zbf/zbf.dart';

abstract interface class LibraryRepository {
  Stream<List<LibraryBook>> watchBooks();

  Future<LibraryBook?> getBook(String id);

  Future<LibraryBook?> findByContentHash(String contentHash);

  Future<LibraryBook> addBookFromIngestion(
    ZbfBook book,
    String zbfPath, {
    String? contentHash,
  });

  Future<LibraryBook> indexExisting(String zbfPath);

  Future<LibraryBook> updateBookMetadata(
    String id, {
    required String title,
    String? author,
    String? genre,
    Uint8List? coverImage,
  });

  Future<void> deleteBook(String id);

  Future<void> touchOpened(String id);

  Future<void> backfill();
}
