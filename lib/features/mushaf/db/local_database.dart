import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'package:the_message_of_the_quran/core/services/database/db_io_utils_stub.dart'
    if (dart.library.io) 'package:the_message_of_the_quran/core/services/database/db_io_utils.dart'
    as db_io;

/// Manages a single SQLite database instance copied from bundled assets.
class LocalDatabase {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();

  /// Increment this whenever the bundled DB.db asset is updated.
  static const int _dbVersion = 3;
  static const String _dbVersionKey = 'mushaf_db_version';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final dbPath = await _copyBundledDatabaseIfNeeded();
    _database = await openDatabase(dbPath, readOnly: true);
    return _database!;
  }

  Future<String> _copyBundledDatabaseIfNeeded() async {
    final databasesPath = await getDatabasesPath();
    final dbPath = p.join(databasesPath, 'mushaf_DB.db');

    final prefs = await SharedPreferences.getInstance();
    final currentVersion = prefs.getInt(_dbVersionKey) ?? 0;

    final exists = await db_io.databaseExistsAt(dbPath);
    if (!exists || currentVersion < _dbVersion) {
      final data = await rootBundle.load('assets/db/DB.db');
      final bytes = data.buffer.asUint8List();
      await db_io.writeAssetDatabase(dbPath, bytes);
      await prefs.setInt(_dbVersionKey, _dbVersion);
    }

    return dbPath;
  }
}
