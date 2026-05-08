import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

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
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'mushaf_DB.db');

    final prefs = await SharedPreferences.getInstance();
    final currentVersion = prefs.getInt(_dbVersionKey) ?? 0;

    final dbFile = File(dbPath);
    if (!await dbFile.exists() || currentVersion < _dbVersion) {
      final data = await rootBundle.load('assets/db/DB.db');
      final bytes = data.buffer.asUint8List();
      await dbFile.writeAsBytes(bytes, flush: true);
      await prefs.setInt(_dbVersionKey, _dbVersion);
    }

    return dbPath;
  }
}
