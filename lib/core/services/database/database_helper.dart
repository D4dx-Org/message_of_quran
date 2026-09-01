import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:the_message_of_the_quran/core/constants/db_constants.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/data/progression_db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'db_io_utils_stub.dart' if (dart.library.io) 'db_io_utils.dart' as db_io;

class DatabaseHelper {
  static const String _createBookmarksTableSql =
      'CREATE TABLE IF NOT EXISTS bookmarks ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'surah_number INTEGER NOT NULL, '
      'ayah_id INTEGER NOT NULL, '
      'surah_name TEXT, '
      'aya_text TEXT, '
      'surah_arabic_name TEXT, '
      'surah_arabic_number TEXT, '
      'label TEXT, '
      'navigation_target TEXT NOT NULL, '
      'page_number INTEGER NOT NULL DEFAULT 0, '
      'UNIQUE(surah_number, ayah_id, navigation_target, page_number)'
      ')';

  static const String _createFavoriteSurahsTableSql =
      'CREATE TABLE IF NOT EXISTS favorite_surahs ('
      'surah_number INTEGER PRIMARY KEY, '
      'created_at INTEGER NOT NULL'
      ')';

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  static Database? quranAsadDb;

  /// The English (Asad) and Malayalam content now live in a single combined
  /// database (`quran_asad_combined_nw.sqlite`). This alias keeps the existing
  /// Malayalam helpers working against the same handle.
  static Database? get quranAsadMalayalamDb => quranAsadDb;
  static Database? userDatabase;

  static Completer<void>? _initCompleter;

  static Future<void> initializeServices() async {
    // Guard against concurrent calls (e.g. hot restart)
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }
    _initCompleter = Completer<void>();
    try {
      await _doInitialize();
      _initCompleter!.complete();
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null;
      rethrow;
    }
  }

  static Future<void> _doInitialize() async {
    // On web, switch the global databaseFactory to the FFI-web implementation.
    db_io.initDatabaseFactory();

    // Close any previously open connections (handles hot restart)
    await _closeAll();
    final prefs = await SharedPreferences.getInstance();

    // ── quran_asad_combined_nw.sqlite (English + Malayalam) ──
    final storedAsadVersion =
        prefs.getInt(DbConstants.quranAsadDbVersionKey) ?? 0;
    if (storedAsadVersion < DbConstants.quranAsadDbVersion) {
      final asadPath = await _databasePathFor(DbConstants.quranAsadDbName);
      // Delete the old database and its journal files
      await db_io.deleteFileIfExists(asadPath);
      await db_io.deleteWalShmFiles(asadPath);
    }

    quranAsadDb = await initDatabase(
      name: DbConstants.quranAsadDbName,
      dbName: DbConstants.quranAsadDbName,
      sanityTable: DbConstants.asadVersesTable,
    );
    await prefs.setInt(
      DbConstants.quranAsadDbVersionKey,
      DbConstants.quranAsadDbVersion,
    );

    final userDbPath = await _databasePathFor(DbConstants.userDbName);
    userDatabase = await openDatabase(
      userDbPath,
      version: 7,
      onConfigure: (db) async {
        await db.rawQuery('PRAGMA journal_mode=WAL');
      },
      onCreate: (db, version) async {
        await db.execute(_createBookmarksTableSql);
        await db.execute(ProgressionDbHelper.createProgressionsTable);
        await db.execute(ProgressionDbHelper.createProgressionDaysTable);
        await db.execute(ProgressionDbHelper.createProgressionAyahsTable);
        await db.execute(_createFavoriteSurahsTableSql);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE bookmarks ADD COLUMN label TEXT');
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE bookmarks ADD COLUMN navigation_target TEXT',
          );
        }
        if (oldVersion < 4) {
          await db.execute(ProgressionDbHelper.createProgressionsTable);
          await db.execute(ProgressionDbHelper.createProgressionDaysTable);
          await db.execute(ProgressionDbHelper.createProgressionAyahsTable);
        }
        if (oldVersion < 6) {
          await db.execute('ALTER TABLE bookmarks RENAME TO bookmarks_legacy');
          await db.execute(_createBookmarksTableSql);
          await db.execute(
            'INSERT OR REPLACE INTO bookmarks ('
            'surah_number, '
            'ayah_id, '
            'surah_name, '
            'aya_text, '
            'surah_arabic_name, '
            'surah_arabic_number, '
            'label, '
            'navigation_target, '
            'page_number'
            ') '
            'SELECT '
            'surah_number, '
            'ayah_id, '
            'surah_name, '
            'aya_text, '
            'surah_arabic_name, '
            'surah_arabic_number, '
            'label, '
            "COALESCE(NULLIF(navigation_target, ''), 'surah'), "
            '0 '
            'FROM bookmarks_legacy',
          );
          await db.execute('DROP TABLE bookmarks_legacy');
        }
        if (oldVersion < 7) {
          await db.execute(_createFavoriteSurahsTableSql);
        }
      },
    );
  }

  static Future<void> _closeAll() async {
    for (final db in [quranAsadDb, userDatabase]) {
      if (db != null && db.isOpen) {
        try {
          await db.close();
        } catch (e) {
          debugPrint('DB: close failed — $e');
        }
      }
    }
    quranAsadDb = null;
    userDatabase = null;
  }

  static Future<Database> initDatabase({
    required String name,
    required String dbName,
    String? sanityTable,
  }) async {
    final path = await _databasePathFor(name);

    Future<void> copyFromAsset() async {
      final data = await rootBundle.load(join(DbConstants.dbLocation, dbName));
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await db_io.writeAssetDatabase(path, bytes);
    }

    // Remove stale WAL/SHM files on startup — they cause
    // SQLITE_CANTOPEN (error 14) on iOS when bundled from macOS.
    if (!kIsWeb) {
      await db_io.deleteWalShmFiles(path);
    }

    final exists = await db_io.databaseExistsAt(path);
    if (!exists) {
      debugPrint("database helper : Creating new copy from asset");
      await copyFromAsset();
    }

    try {
      final db = await openDatabase(path, readOnly: !kIsWeb);
      if (await _isUsable(db, sanityTable)) return db;
      // The file opened but has no readable content — seen on a first launch
      // where the freshly written copy was not complete. Queries against it
      // return nothing rather than throwing, so the app comes up with empty
      // surahs until the next launch reopens a settled file. Re-copy instead.
      debugPrint("database helper : Re-copying asset — opened db is unusable");
      await db.close();
      await copyFromAsset();
      return await openDatabase(path, readOnly: !kIsWeb);
    } catch (e) {
      debugPrint("database helper : Re-copying asset due to open failure: $e");
      await copyFromAsset();
      return await openDatabase(path, readOnly: !kIsWeb);
    }
  }

  /// True when [sanityTable] exists and holds rows. A copy that was cut short
  /// still opens as a valid — but empty — database, so presence alone is not
  /// enough to trust it.
  static Future<bool> _isUsable(Database db, String? sanityTable) async {
    if (sanityTable == null) return true;
    try {
      final rows = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM $sanityTable LIMIT 1',
      );
      final count = Sqflite.firstIntValue(rows) ?? 0;
      if (count == 0) {
        debugPrint("database helper : $sanityTable is empty");
      }
      return count > 0;
    } catch (e) {
      debugPrint("database helper : sanity check on $sanityTable failed — $e");
      return false;
    }
  }

  static Future<String> _databasePathFor(String name) async {
    if (kIsWeb) {
      return name;
    }

    final databasesPath = await getDatabasesPath();
    return join(databasesPath, name);
  }
}
