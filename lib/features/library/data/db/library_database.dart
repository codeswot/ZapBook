import 'package:drift/drift.dart';

import 'package:zapbook/features/library/data/db/tables/books_table.dart';

part 'library_database.g.dart';

@DriftDatabase(tables: [Books], daos: [BooksDao])
class LibraryDatabase extends _$LibraryDatabase {
  LibraryDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}

@DriftAccessor(tables: [Books])
class BooksDao extends DatabaseAccessor<LibraryDatabase> with _$BooksDaoMixin {
  BooksDao(super.db);

  Stream<List<BookRow>> watchAll() {
    return (select(books)
          ..orderBy([(b) => OrderingTerm.desc(b.addedAt)]))
        .watch();
  }

  Future<BookRow?> getById(String id) {
    return (select(books)..where((b) => b.id.equals(id))).getSingleOrNull();
  }

  Future<void> upsert(BooksCompanion row) {
    return into(books).insertOnConflictUpdate(row);
  }

  Future<int> deleteById(String id) {
    return (delete(books)..where((b) => b.id.equals(id))).go();
  }

  Future<void> touchOpened(String id, DateTime when) {
    return (update(books)..where((b) => b.id.equals(id)))
        .write(BooksCompanion(lastOpenedAt: Value(when)));
  }

  Future<List<String>> allZbfPaths() async {
    final query = selectOnly(books)..addColumns([books.zbfPath]);
    final rows = await query.get();
    return rows.map((row) => row.read(books.zbfPath)!).toList();
  }
}
