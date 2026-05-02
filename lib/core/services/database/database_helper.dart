import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:the_message_of_the_quran/core/constants/db_constants.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/data/progression_db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  static Database? quranMalayalamDb; // disabled — kept for future use
  static Database? quranAsadDb;
  static Database? userDatabase;

  static Future<void> initializeServices() async {
    final prefs = await SharedPreferences.getInstance();

    // ── quran_malayalam_.db — disabled for now ──
    // quranMalayalamDb = await initDatabase(
    //   name: DbConstants.quranMalayalamDbName,
    //   dbName: DbConstants.quranMalayalamDbName,
    // );

    // ── quran_asad.sqlite ──
    final storedAsadVersion =
        prefs.getInt(DbConstants.quranAsadDbVersionKey) ?? 0;
    if (storedAsadVersion < DbConstants.quranAsadDbVersion) {
      final databasesPath2 = await getDatabasesPath();
      final asadPath = join(databasesPath2, DbConstants.quranAsadDbName);
      for (final suffix in ['', '-wal', '-shm']) {
        try {
          await File('$asadPath$suffix').delete();
        } catch (e) {
          debugPrint('DB: failed to delete $asadPath$suffix — $e');
        }
      }
    }

    quranAsadDb = await initDatabase(
      name: DbConstants.quranAsadDbName,
      dbName: DbConstants.quranAsadDbName,
    );
    await prefs.setInt(
      DbConstants.quranAsadDbVersionKey,
      DbConstants.quranAsadDbVersion,
    );

    final databasesPath = await getDatabasesPath();
    final userDbPath = join(databasesPath, DbConstants.userDbName);
    userDatabase = await openDatabase(
      userDbPath,
      version: 4,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE IF NOT EXISTS bookmarks (id INTEGER PRIMARY KEY AUTOINCREMENT, surah_number INTEGER NOT NULL, ayah_id INTEGER NOT NULL, surah_name TEXT, aya_text TEXT, surah_arabic_name TEXT, surah_arabic_number TEXT, label TEXT, navigation_target TEXT, UNIQUE(surah_number, ayah_id))',
        );
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
      },
    );
  }

  static Future<Database> initDatabase({
    required String name,
    required String dbName,
  }) async {
    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, name);

    Future<void> copyFromAsset() async {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (e) {
        debugPrint('DB: failed to create directory — $e');
      }
      // Remove stale WAL/SHM journal files if present
      for (final suffix in ['-wal', '-shm']) {
        try {
          await File('$path$suffix').delete();
        } catch (e) {
          debugPrint('DB: failed to delete $path$suffix — $e');
        }
      }
      // Remove old database file
      try {
        await File(path).delete();
      } catch (e) {
        debugPrint('DB: failed to delete old db — $e');
      }
      final data = await rootBundle.load(join(DbConstants.dbLocation, dbName));
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await File(path).writeAsBytes(bytes, flush: true);
    }

    // Always remove stale WAL/SHM files on startup — they cause
    // SQLITE_CANTOPEN (error 14) on iOS when bundled from macOS.
    for (final suffix in ['-wal', '-shm']) {
      final sideFile = File('$path$suffix');
      if (await sideFile.exists()) {
        debugPrint(
          "database helper : Removing stale journal file: $path$suffix",
        );
        try {
          await sideFile.delete();
        } catch (e) {
          debugPrint('database helper : Failed to delete $path$suffix – $e');
        }
      }
    }

    final exists = await databaseExists(path);
    if (!exists) {
      debugPrint("database helper : Creating new copy from asset");
      await copyFromAsset();
    }

    try {
      return await openDatabase(path);
    } catch (e) {
      debugPrint("database helper : Re-copying asset due to open failure: $e");
      await copyFromAsset();
      return await openDatabase(path);
    }
  }
}
