import 'dart:typed_data';

import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/features/library/domain/entities/share_skip.dart';
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

  Future<List<ShareSkip>> shareBook(String id, String memberNpub);

  Future<List<ShareSkip>> shareBookWith(String id, List<String> memberNpubs);

  Future<List<String>> bookMembers(String id);

  Future<void> removeBookMember(String id, String memberNpub);

  Future<void> refresh();

  Future<void> backfill();
}
