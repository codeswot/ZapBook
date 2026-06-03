import 'package:drift/drift.dart';

@DataClassName('BookRow')
@TableIndex(name: 'idx_books_added_at', columns: {#addedAt})
@TableIndex(name: 'idx_books_content_hash', columns: {#contentHash})
class Books extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get author => text()();
  TextColumn get genre => text().nullable()();
  TextColumn get contentHash => text().nullable()();
  TextColumn get sourceFormat => text()();
  IntColumn get pageCount => integer()();
  IntColumn get chapterCount => integer()();
  TextColumn get zbfPath => text()();
  TextColumn get coverPath => text().nullable()();
  BoolColumn get needsAiProcessing => boolean()();
  TextColumn get zbfVersion => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get addedAt => dateTime()();
  DateTimeColumn get lastOpenedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
