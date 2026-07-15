import 'dart:async';

import 'package:injectable/injectable.dart';

import 'package:zapbook/core/data/infrastructure/circle_store_service.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/features/library/domain/repositories/library_repository.dart';

@LazySingleton(as: LibraryRepository)
class LibraryRepositoryImpl implements LibraryRepository {
  LibraryRepositoryImpl(this._circleStore);

  final CircleStoreService _circleStore;

  @override
  Stream<List<CircleBook>> watchBooks() => _circleStore.watchCircleBooks;

  @override
  Stream<CircleBook?> watchLastOpenedBook() =>
      _circleStore.watchLastOpenedCircleBook;

  @override
  Future<CircleBook?> getBook(String id) async {
    return _circleStore.currentCircles.where((c) => c.id == id).firstOrNull;
  }

  @override
  Future<void> deleteBook(CircleBook book) =>
      _circleStore.deleteCircleBook(book);
}
