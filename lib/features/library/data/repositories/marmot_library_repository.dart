import 'dart:async';

import 'package:injectable/injectable.dart';

import 'package:zapbook/core/services/circle_store_service.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/features/library/domain/repositories/library_repository.dart';

@LazySingleton(as: LibraryRepository)
class LibraryRepositoryImpl implements LibraryRepository {
  LibraryRepositoryImpl(this._circleStore);

  final CircleStoreService _circleStore;

  @override
  Stream<List<CircleBook>> watchBooks() => _circleStore.watchCircles;

  @override
  Stream<CircleBook?> watchLastOpenedBook() => _circleStore.watchLastOpenedCircleBook;

  @override
  Future<CircleBook?> getBook(String id) async {
    final circles = _circleStore.currentCircles;
    for (final circle in circles) {
      if (circle.id == id) return circle;
    }
    return null;
  }
}
