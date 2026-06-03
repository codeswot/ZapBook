import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/zbf/zbf.dart';

abstract interface class LibraryRepository {
  Stream<List<LibraryBook>> watchBooks();

  Future<LibraryBook?> getBook(String id);

  Future<LibraryBook> addBookFromIngestion(ZbfBook book, String zbfPath);

  Future<LibraryBook> indexExisting(String zbfPath);

  Future<void> deleteBook(String id);

  Future<void> touchOpened(String id);

  Future<void> backfill();
}
