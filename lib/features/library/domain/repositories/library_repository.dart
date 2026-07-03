import 'package:zapbook/core/domain/entities/circle_book.dart';

abstract interface class LibraryRepository {
  Stream<List<CircleBook>> watchBooks();
  Stream<CircleBook?> watchLastOpenedBook();
  Future<CircleBook?> getBook(String id);
  Future<void> deleteBook(CircleBook book);
}
