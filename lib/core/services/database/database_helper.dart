import 'dart:async';

import 'package:flutter/foundation.dart';
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

  /// Holds bookmarks and progressions only. The Qur'an content is served by the
  /// backend, so no content database is bundled or opened any more.
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

    await _removeBundledContentDatabase();

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
    final db = userDatabase;
    if (db != null && db.isOpen) {
      try {
        await db.close();
      } catch (e) {
        debugPrint('DB: close failed — $e');
      }
    }
    userDatabase = null;
  }

  /// Earlier versions copied two bundled databases onto the device: the ~52 MB
  /// Qur'an content and the ~15 MB mushaf page data. Both are served by the
  /// backend now, so any leftover copy is dead weight and is deleted once on
  /// the first launch after upgrading.
  static Future<void> _removeBundledContentDatabase() async {
    const obsolete = <String, String>{
      DbConstants.quranAsadDbVersionKey: DbConstants.quranAsadDbName,
      // LocalDatabase's own key and the name it copied assets/db/DB.db to.
      'mushaf_db_version': 'mushaf_DB.db',
    };

    final prefs = await SharedPreferences.getInstance();
    for (final entry in obsolete.entries) {
      if (!prefs.containsKey(entry.key)) continue;

      try {
        final path = await _databasePathFor(entry.value);
        await db_io.deleteFileIfExists(path);
        await db_io.deleteWalShmFiles(path);
        debugPrint('database helper : Removed obsolete ${entry.value}');
      } catch (e) {
        debugPrint('database helper : Could not remove ${entry.value} — $e');
      }

      await prefs.remove(entry.key);
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
