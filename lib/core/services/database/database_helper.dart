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
      'UNIQUE(surah_number, ayah_id, navigation_target)'
      ')';

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  static Database? quranAsadDb;
  static Database? quranAsadMalayalamDb;
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

    // ── quran_asad.sqlite ──
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
    );
    await prefs.setInt(
      DbConstants.quranAsadDbVersionKey,
      DbConstants.quranAsadDbVersion,
    );

    // ── quran_asad_malayalam.db ──
    final storedMalayalamVersion =
        prefs.getInt(DbConstants.quranAsadMalayalamDbVersionKey) ?? 0;
    if (storedMalayalamVersion < DbConstants.quranAsadMalayalamDbVersion) {
      final mlPath = await _databasePathFor(
        DbConstants.quranAsadMalayalamDbName,
      );
      await db_io.deleteFileIfExists(mlPath);
      await db_io.deleteWalShmFiles(mlPath);
    }

    quranAsadMalayalamDb = await initDatabase(
      name: DbConstants.quranAsadMalayalamDbName,
      dbName: DbConstants.quranAsadMalayalamDbName,
    );
    await prefs.setInt(
      DbConstants.quranAsadMalayalamDbVersionKey,
      DbConstants.quranAsadMalayalamDbVersion,
    );

    final userDbPath = await _databasePathFor(DbConstants.userDbName);
    userDatabase = await openDatabase(
      userDbPath,
      version: 5,
      onConfigure: (db) async {
        await db.rawQuery('PRAGMA journal_mode=WAL');
      },
      onCreate: (db, version) async {
        await db.execute(_createBookmarksTableSql);
        await db.execute(ProgressionDbHelper.createProgressionsTable);
        await db.execute(ProgressionDbHelper.createProgressionDaysTable);
        await db.execute(ProgressionDbHelper.createProgressionAyahsTable);
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
        if (oldVersion < 5) {
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
            'navigation_target'
            ') '
            'SELECT '
            'surah_number, '
            'ayah_id, '
            'surah_name, '
            'aya_text, '
            'surah_arabic_name, '
            'surah_arabic_number, '
            'label, '
            "COALESCE(NULLIF(navigation_target, ''), 'surah') "
            'FROM bookmarks_legacy',
          );
          await db.execute('DROP TABLE bookmarks_legacy');
        }
      },
    );
  }

  static Future<void> _closeAll() async {
    for (final db in [quranAsadDb, quranAsadMalayalamDb, userDatabase]) {
      if (db != null && db.isOpen) {
        try {
          await db.close();
        } catch (e) {
          debugPrint('DB: close failed — $e');
        }
      }
    }
    quranAsadDb = null;
    quranAsadMalayalamDb = null;
    userDatabase = null;
  }

  static Future<Database> initDatabase({
    required String name,
    required String dbName,
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
      return await openDatabase(path, readOnly: !kIsWeb);
    } catch (e) {
      debugPrint("database helper : Re-copying asset due to open failure: $e");
      await copyFromAsset();
      return await openDatabase(path, readOnly: !kIsWeb);
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
