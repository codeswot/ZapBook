import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

@singleton
class AppDatabase {
  AppDatabase() : _dbPath = null;
  AppDatabase.forPath(String dbPath) : _dbPath = dbPath;

  String? _dbPath;
  Database? _db;

  Future<String> _path() async {
    if (_dbPath != null) return _dbPath!;
    final dir = await getApplicationSupportDirectory();
    return _dbPath = '${dir.path}/zapbook.db';
  }

  Future<Database> open() async {
    final existing = _db;
    if (existing != null) return existing;

    final db = sqlite3.open(await _path());
    db.execute('PRAGMA journal_mode=WAL');

    _createBookPagesTable(db);
    _createCheersFeedTable(db);

    return _db = db;
  }

  void _createBookPagesTable(Database db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS book_pages (
        book_id TEXT NOT NULL,
        page_index INTEGER NOT NULL,
        json TEXT NOT NULL,
        PRIMARY KEY (book_id, page_index)
      )
    ''');
  }

  void _createCheersFeedTable(Database db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS cheers_feed (
        id TEXT PRIMARY KEY,
        actor_npub TEXT NOT NULL,
        actor_name TEXT NOT NULL,
        actor_avatar TEXT,
        book_title TEXT NOT NULL,
        book_id TEXT,
        activity_description TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        type TEXT NOT NULL,
        is_unread INTEGER NOT NULL,
        nudge_id TEXT,
        thumbs_up_count INTEGER NOT NULL,
        clap_count INTEGER NOT NULL,
        fire_count INTEGER NOT NULL,
        rocket_count INTEGER NOT NULL,
        trophy_count INTEGER NOT NULL,
        zap_amount INTEGER,
        zap_reaction TEXT,
        zap_target_id TEXT,
        zap_target_description TEXT,
        zap_recipient_npub TEXT
      )
    ''');
    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_cheers_timestamp ON cheers_feed(timestamp DESC)',
    );
  }

  void close() {
    _db?.close();
    _db = null;
  }
}
