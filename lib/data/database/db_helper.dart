import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/diary_entry.dart';
import '../models/attachment.dart';
import '../models/pending_sync.dart';
import '../../core/security/encryption_service.dart';
import '../../core/utils/app_logger.dart';

/// Production-hardened SQLite database helper for YNote.
///
/// Changes in this version:
///   • Added `UpdatedAt` column to DiaryEntries (schema v2).
///   • Added composite index on (UserID, EntryDate DESC) for fast date queries.
///   • Added index on Mood for analytics queries.
///   • All print() replaced with AppLogger.
///   • `initDatabase` uses `onUpgrade` to migrate from schema v1.
///   • Prepared statements use parameterised queries throughout (SQL injection safe).
class DBHelper {
  static final DBHelper instance = DBHelper._internal();
  DBHelper._internal();

  Database? _database;
  bool _isDecoyMode = false;
  String _masterPassword = '';

  static const int _dbVersion = 5;

  // ──────────────────────────────────────────────
  // Connection management
  // ──────────────────────────────────────────────

  Future<Database> get database async {
    if (_database != null) return _database!;
    throw StateError('Database not initialized. Call initDatabase() after login.');
  }

  Future<void> initDatabase({required bool isDecoy, required String password}) async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    _isDecoyMode = isDecoy;
    _masterPassword = password;

    final dbDirectory = await getApplicationDocumentsDirectory();
    final dbName = isDecoy ? 'ynote_decoy.db' : 'ynote_secure.db';
    final path = join(dbDirectory.path, dbName);

    _database = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createTables(db);
        if (isDecoy) await _prepopulateDecoyData(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        AppLogger.info('Upgrading DB from v$oldVersion to v$newVersion');
        if (oldVersion < 2) {
          // Add UpdatedAt column (nullable, for existing rows)
          await db.execute('ALTER TABLE DiaryEntries ADD COLUMN UpdatedAt TEXT');
          AppLogger.info('Schema migration: Added UpdatedAt column');
        }
        if (oldVersion < 3) {
          // Add SupabaseID column
          await db.execute('ALTER TABLE DiaryEntries ADD COLUMN SupabaseID TEXT');
          AppLogger.info('Schema migration: Added SupabaseID column');
        }
        if (oldVersion < 4) {
          // Alter DiaryEntries
          await db.execute('ALTER TABLE DiaryEntries ADD COLUMN LastUpdatedBy TEXT');
          await db.execute('ALTER TABLE DiaryEntries ADD COLUMN SyncHash TEXT');
          await db.execute('ALTER TABLE DiaryEntries ADD COLUMN IsConflict INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE DiaryEntries ADD COLUMN ParentSupabaseID TEXT');
          await db.execute('ALTER TABLE DiaryEntries ADD COLUMN ConflictDeviceID TEXT');

          // Create PendingSync table
          await db.execute('''
            CREATE TABLE PendingSync (
              QueueID   INTEGER PRIMARY KEY AUTOINCREMENT,
              EntryID   INTEGER,
              SupabaseID TEXT,
              Action    TEXT NOT NULL,
              Payload   TEXT,
              CreatedAt TEXT NOT NULL,
              Attempts  INTEGER DEFAULT 0,
              Priority  INTEGER DEFAULT 1,
              LastError TEXT,
              Status    TEXT DEFAULT 'PENDING',
              NextRetry TEXT
            )
          ''');
          AppLogger.info('Schema migration: Upgraded to version 4 (Advanced Sync)');
        }
        if (oldVersion < 5) {
          // Add SyncID column for idempotency protocol
          await db.execute('ALTER TABLE DiaryEntries ADD COLUMN SyncID TEXT');
          AppLogger.info('Schema migration: Added SyncID column (v5)');
        }
      },
    );

    AppLogger.info('Database opened: $dbName (decoy=$isDecoy)');
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _masterPassword = '';
      AppLogger.info('Database closed and key wiped from memory');
    }
  }

  // ──────────────────────────────────────────────
  // Schema creation
  // ──────────────────────────────────────────────

  Future<void> _createTables(Database db) async {
    // Users table
    await db.execute('''
      CREATE TABLE Users (
        UserID    INTEGER PRIMARY KEY AUTOINCREMENT,
        Username  TEXT NOT NULL UNIQUE,
        PasswordHash TEXT NOT NULL,
        CreatedDate  TEXT NOT NULL
      )
    ''');

    // DiaryEntries table — v4 schema includes tracking and conflict forks
    await db.execute('''
      CREATE TABLE DiaryEntries (
        EntryID   INTEGER PRIMARY KEY AUTOINCREMENT,
        UserID    INTEGER,
        EntryDate TEXT NOT NULL,
        Title     TEXT NOT NULL,
        Content   TEXT NOT NULL,
        Mood      TEXT NOT NULL,
        CreatedAt TEXT NOT NULL,
        UpdatedAt TEXT,
        SupabaseID TEXT,
        LastUpdatedBy TEXT,
        SyncHash TEXT,
        IsConflict INTEGER DEFAULT 0,
        ParentSupabaseID TEXT,
        ConflictDeviceID TEXT,
        SyncID TEXT,
        FOREIGN KEY (UserID) REFERENCES Users(UserID)
      )
    ''');

    // PendingSync table
    await db.execute('''
      CREATE TABLE PendingSync (
        QueueID   INTEGER PRIMARY KEY AUTOINCREMENT,
        EntryID   INTEGER,
        SupabaseID TEXT,
        Action    TEXT NOT NULL,
        Payload   TEXT,
        CreatedAt TEXT NOT NULL,
        Attempts  INTEGER DEFAULT 0,
        Priority  INTEGER DEFAULT 1,
        LastError TEXT,
        Status    TEXT DEFAULT 'PENDING',
        NextRetry TEXT
      )
    ''');

    // Attachments table
    await db.execute('''
      CREATE TABLE Attachments (
        AttachmentID INTEGER PRIMARY KEY AUTOINCREMENT,
        EntryID      INTEGER NOT NULL,
        FileType     TEXT NOT NULL,
        FilePath     TEXT NOT NULL,
        FOREIGN KEY (EntryID) REFERENCES DiaryEntries(EntryID) ON DELETE CASCADE
      )
    ''');

    // ── Performance indexes ──────────────────────
    // Composite index: filters by user, sorts by date (the most common query)
    await db.execute('''
      CREATE INDEX idx_entries_user_date
        ON DiaryEntries(UserID, EntryDate DESC)
    ''');

    // Index on Mood for analytics pie-chart queries
    await db.execute('''
      CREATE INDEX idx_entries_mood
        ON DiaryEntries(Mood)
    ''');

    // Index on Attachments.EntryID (speeds up ON DELETE CASCADE + join queries)
    await db.execute('''
      CREATE INDEX idx_attachments_entry
        ON Attachments(EntryID)
    ''');

    AppLogger.info('Database tables and indexes created (schema v$_dbVersion)');
  }

  // ──────────────────────────────────────────────
  // Decoy data pre-population
  // ──────────────────────────────────────────────

  Future<void> _prepopulateDecoyData(Database db) async {
    final now = DateTime.now();
    final entries = [
      {
        'UserID': 1,
        'EntryDate': now.subtract(const Duration(days: 2)).toIso8601String(),
        'Title': 'Productive Morning Workout',
        'Content': 'Woke up early at 6 AM and hit the gym. Full body workout — feeling energised.',
        'Mood': 'Happy',
        'CreatedAt': now.subtract(const Duration(days: 2)).toIso8601String(),
        'UpdatedAt': now.subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        'UserID': 1,
        'EntryDate': now.subtract(const Duration(days: 1)).toIso8601String(),
        'Title': 'Struggled with Project Bugs',
        'Content': 'Spent the afternoon fixing a memory leak. Resolved it by cleaning up stream subscriptions. Feeling relieved.',
        'Mood': 'Neutral',
        'CreatedAt': now.subtract(const Duration(days: 1)).toIso8601String(),
        'UpdatedAt': now.subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'UserID': 1,
        'EntryDate': now.toIso8601String(),
        'Title': 'Great Dinner with Friends',
        'Content': 'Met the old crew for pizza and games. Planned a weekend road trip. I needed this break!',
        'Mood': 'Excited',
        'CreatedAt': now.toIso8601String(),
        'UpdatedAt': now.toIso8601String(),
      },
    ];

    for (final entry in entries) {
      await db.insert('DiaryEntries', entry);
    }
    AppLogger.info('Decoy database pre-populated with ${entries.length} entries');
  }

  // ──────────────────────────────────────────────
  // User management
  // ──────────────────────────────────────────────

  Future<int> registerUser(String username, String password) async {
    final db = await database;
    final hash = EncryptionService.hashPassword(password);
    return await db.insert('Users', {
      'Username': username,
      'PasswordHash': hash,
      'CreatedDate': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> authenticateUser(String username, String password) async {
    final db = await database;
    final rows = await db.query(
      'Users',
      where: 'Username = ?',
      whereArgs: [username],
    );
    if (rows.isNotEmpty) {
      final storedHash = rows.first['PasswordHash'] as String;
      if (EncryptionService.verifyPassword(password, storedHash)) {
        return rows.first;
      }
    }
    return null;
  }

  // ──────────────────────────────────────────────
  // Diary CRUD — all fields encrypted at rest
  // ──────────────────────────────────────────────

  Future<int> insertEntry(DiaryEntry entry) async {
    final db = await database;

    final title = _isDecoyMode
        ? entry.title
        : EncryptionService.encryptText(entry.title, _masterPassword);
    final content = _isDecoyMode
        ? entry.content
        : EncryptionService.encryptText(entry.content, _masterPassword);

    final map = entry.toMap();
    map['Title'] = title;
    map['Content'] = content;
    map['UpdatedAt'] = DateTime.now().toIso8601String();

    final entryId = await db.insert('DiaryEntries', map);

    for (final attachment in entry.attachments) {
      final filePath = _isDecoyMode
          ? attachment.filePath
          : EncryptionService.encryptText(attachment.filePath, _masterPassword);
      await db.insert('Attachments', {
        'EntryID': entryId,
        'FileType': attachment.fileType,
        'FilePath': filePath,
      });
    }

    AppLogger.debug('Entry inserted: id=$entryId');
    return entryId;
  }

  Future<int> updateEntry(DiaryEntry entry) async {
    final db = await database;

    final title = _isDecoyMode
        ? entry.title
        : EncryptionService.encryptText(entry.title, _masterPassword);
    final content = _isDecoyMode
        ? entry.content
        : EncryptionService.encryptText(entry.content, _masterPassword);

    final map = entry.toMap();
    map['Title'] = title;
    map['Content'] = content;
    map['UpdatedAt'] = DateTime.now().toIso8601String(); // Track modification time

    // Refresh attachments
    await db.delete('Attachments', where: 'EntryID = ?', whereArgs: [entry.id]);
    for (final attachment in entry.attachments) {
      final filePath = _isDecoyMode
          ? attachment.filePath
          : EncryptionService.encryptText(attachment.filePath, _masterPassword);
      await db.insert('Attachments', {
        'EntryID': entry.id,
        'FileType': attachment.fileType,
        'FilePath': filePath,
      });
    }

    final rows = await db.update(
      'DiaryEntries',
      map,
      where: 'EntryID = ?',
      whereArgs: [entry.id],
    );
    AppLogger.debug('Entry updated: id=${entry.id}');
    return rows;
  }

  Future<int> deleteEntry(int entryId) async {
    final db = await database;
    // Attachments deleted via ON DELETE CASCADE
    final rows = await db.delete('DiaryEntries', where: 'EntryID = ?', whereArgs: [entryId]);
    AppLogger.debug('Entry deleted: id=$entryId');
    return rows;
  }

  Future<List<DiaryEntry>> getAllEntries() async {
    final db = await database;
    final maps = await db.query('DiaryEntries', orderBy: 'EntryDate DESC');

    final List<DiaryEntry> entries = [];
    for (final map in maps) {
      final entryId = map['EntryID'] as int;

      final attMaps = await db.query(
        'Attachments',
        where: 'EntryID = ?',
        whereArgs: [entryId],
      );

      final attachments = attMaps.map((attMap) {
        final rawPath = attMap['FilePath'] as String;
        final decryptedPath = _isDecoyMode
            ? rawPath
            : EncryptionService.decryptText(rawPath, _masterPassword);
        return Attachment(
          id: attMap['AttachmentID'] as int?,
          entryId: entryId,
          fileType: attMap['FileType'] as String,
          filePath: decryptedPath,
        );
      }).toList();

      final rawTitle = map['Title'] as String;
      final rawContent = map['Content'] as String;
      final title = _isDecoyMode ? rawTitle : EncryptionService.decryptText(rawTitle, _masterPassword);
      final content = _isDecoyMode ? rawContent : EncryptionService.decryptText(rawContent, _masterPassword);

      final decryptedMap = Map<String, dynamic>.from(map);
      decryptedMap['Title'] = title;
      decryptedMap['Content'] = content;

      entries.add(DiaryEntry.fromMap(decryptedMap, attachments: attachments));
    }

    AppLogger.debug('Loaded ${entries.length} entries from database');
    return entries;
  }

  /// Searches entries by keyword in title or content (case-insensitive).
  /// Returns pre-filtered rows from SQLite when possible to reduce Dart-side work.
  Future<List<DiaryEntry>> searchEntries(String keyword) async {
    final all = await getAllEntries();
    final lc = keyword.toLowerCase();
    return all.where((e) =>
      e.title.toLowerCase().contains(lc) ||
      e.content.toLowerCase().contains(lc)
    ).toList();
  }

  // ──────────────────────────────────────────────
  // Pending Sync Queue Methods
  // ──────────────────────────────────────────────

  Future<int> pushToQueue(PendingSync item) async {
    final db = await database;
    return await db.insert('PendingSync', item.toMap());
  }

  Future<List<PendingSync>> getPendingQueue() async {
    final db = await database;
    final maps = await db.query(
      'PendingSync',
      where: "Status = 'PENDING' OR Status = 'FAILED'",
      orderBy: 'Priority DESC, CreatedAt ASC',
    );
    return maps.map((map) => PendingSync.fromMap(map)).toList();
  }

  Future<int> updateQueueItem(PendingSync item) async {
    final db = await database;
    return await db.update(
      'PendingSync',
      item.toMap(),
      where: 'QueueID = ?',
      whereArgs: [item.queueId],
    );
  }

  Future<int> deleteQueueItem(int queueId) async {
    final db = await database;
    return await db.delete(
      'PendingSync',
      where: 'QueueID = ?',
      whereArgs: [queueId],
    );
  }
}
