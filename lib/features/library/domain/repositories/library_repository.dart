import 'package:zapbook/core/domain/entities/circle_book.dart';

abstract interface class LibraryRepository {
  Stream<List<CircleBook>> watchBooks();
  Future<CircleBook?> getBook(String id);
}
