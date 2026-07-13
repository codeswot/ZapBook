import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:zapbook/core/di/marmot_module.dart';
import 'dart:typed_data';

@singleton
class AppDatabase {
  AppDatabase() : _dbPath = null, _isTest = false;
  AppDatabase.forPath(String dbPath) : _dbPath = dbPath, _isTest = true;

  final bool _isTest;

  String? _dbPath;
  Database? _db;

  Future<String> _path() async {
    if (_dbPath != null) return _dbPath!;
    final dir = await getApplicationSupportDirectory();
    return _dbPath = '${dir.path}/zapbook.db';
  }

  String _toHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  Future<Database> open() async {
    final existing = _db;
    if (existing != null) return existing;

    final db = sqlite3.open(await _path());

    if (_isTest) {
      final key = Uint8List(32);
      db.execute("PRAGMA key = \"x'${_toHex(key)}'\";");
    } else {
      final key = await MarmotWarmup.getSecureDbKey();
      db.execute("PRAGMA key = \"x'${_toHex(key)}'\";");
    }

    db.execute('PRAGMA journal_mode=WAL');

    _createBookPagesTable(db);
    _createCheersFeedTable(db);
    _createCircleMemberProgressTable(db);
    _createReadingStatsTable(db);
    _createZapSatsEarningsTable(db);

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

  void _createReadingStatsTable(Database db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS reading_stats (
        pub_key TEXT PRIMARY KEY,
        streak INTEGER NOT NULL DEFAULT 0,
        last_activity_date TEXT,
        books_read INTEGER NOT NULL DEFAULT 0,
        sats_earned INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  void _createCircleMemberProgressTable(Database db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS circle_member_progress (
        group_id TEXT NOT NULL,
        pub_key TEXT NOT NULL,
        book_id TEXT NOT NULL,
        page_index INTEGER NOT NULL,
        progress_percentage REAL NOT NULL,
        updated_at INTEGER NOT NULL,
        milestones_reached INTEGER NOT NULL DEFAULT 0,
        completed INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (group_id, pub_key, book_id)
      )
    ''');
    _addColumnIfMissing(
      db,
      'circle_member_progress',
      'milestones_reached',
      'INTEGER NOT NULL DEFAULT 0',
    );
    _addColumnIfMissing(
      db,
      'circle_member_progress',
      'completed',
      'INTEGER NOT NULL DEFAULT 0',
    );
  }

  void _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String definition,
  ) {
    final info = db.select('PRAGMA table_info($table)');
    final exists = info.any((row) => row['name'] == column);
    if (!exists) {
      db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  void _createCheersFeedTable(Database db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS cheers_feed (
        id TEXT PRIMARY KEY,
        actor_npub TEXT NOT NULL,        
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
        zap_recipient_npub TEXT,
        group_id TEXT
      )
    ''');
    _addColumnIfMissing(db, 'cheers_feed', 'group_id', 'TEXT');
    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_cheers_timestamp ON cheers_feed(timestamp DESC)',
    );
  }

  void _createZapSatsEarningsTable(Database db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS zap_sats_earnings (
        id TEXT PRIMARY KEY,
        sender_npub TEXT NOT NULL,
        activity_id TEXT NOT NULL,
        zap_type TEXT NOT NULL,
        sats INTEGER NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');
    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_zap_sats_earnings_timestamp ON zap_sats_earnings(timestamp DESC)',
    );
  }

  void close() {
    _db?.close();
    _db = null;
  }
}
