import 'dart:typed_data';

import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/features/library/domain/entities/share_skip.dart';
import 'package:zapbook/zbf/zbf.dart';

abstract interface class LibraryRepository {
  Stream<List<CircleBook>> watchBooks();

  Future<CircleBook?> getBook(String id);

  Future<CircleBook?> findByContentHash(String contentHash);

  Future<CircleBook> addBookFromIngestion(
    ZbfBook book,
    String zbfPath, {
    String? contentHash,
  });

  Future<CircleBook> indexExisting(String zbfPath);

  Future<CircleBook> updateBookMetadata(
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

  Future<List<String>> bookAdmins(String id);

  Future<void> removeBookMember(String id, String memberNpub);

  Future<void> leaveCircle(String id);

  Future<void> dissolveCircle(String id);

  Future<void> refresh();

  Future<void> backfill();
}
