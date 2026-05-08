import 'package:the_message_of_the_quran/core/services/database/database_helper.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/models/progression_model.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/models/progression_day_model.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/models/progression_ayah_model.dart';
import 'package:sqflite/sqflite.dart';

class ProgressionDbHelper {
  static Database get _db {
    final db = DatabaseHelper.userDatabase;
    if (db == null) {
      throw StateError('User database is not initialized. '
          'Ensure DatabaseHelper.initializeServices() completes before '
          'accessing ProgressionDbHelper.');
    }
    return db;
  }

  // ── SQL for table creation ──────────────────────────────────────────────

  static const String createProgressionsTable = '''
    CREATE TABLE IF NOT EXISTS progressions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      surah_number INTEGER NOT NULL,
      surah_name TEXT NOT NULL,
      arabic_name TEXT,
      place TEXT,
      total_ayahs INTEGER NOT NULL,
      total_days INTEGER NOT NULL,
      ayahs_per_day INTEGER NOT NULL,
      reminder_time TEXT,
      reminder_days TEXT,
      created_at TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'active'
    )
  ''';

  static const String createProgressionDaysTable = '''
    CREATE TABLE IF NOT EXISTS progression_days (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      progression_id INTEGER NOT NULL,
      day_number INTEGER NOT NULL,
      start_ayah INTEGER NOT NULL,
      end_ayah INTEGER NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending',
      FOREIGN KEY (progression_id) REFERENCES progressions(id) ON DELETE CASCADE
    )
  ''';

  static const String createProgressionAyahsTable = '''
    CREATE TABLE IF NOT EXISTS progression_ayahs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      progression_id INTEGER NOT NULL,
      day_id INTEGER NOT NULL,
      ayah_number INTEGER NOT NULL,
      status TEXT NOT NULL DEFAULT 'locked',
      FOREIGN KEY (progression_id) REFERENCES progressions(id) ON DELETE CASCADE,
      FOREIGN KEY (day_id) REFERENCES progression_days(id) ON DELETE CASCADE
    )
  ''';

  // ── Progressions CRUD ──────────────────────────────────────────────────

  static Future<int> insertProgression(
    ProgressionModel progression, {
    DatabaseExecutor? txn,
  }) async {
    return await (txn ?? _db).insert('progressions', progression.toMap());
  }

  static Future<List<ProgressionModel>> getAllProgressions() async {
    final result = await _db.query(
      'progressions',
      orderBy: 'created_at DESC',
    );
    return result.map((m) => ProgressionModel.fromMap(m)).toList();
  }

  static Future<ProgressionModel?> getProgressionById(int id) async {
    final result = await _db.query(
      'progressions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return ProgressionModel.fromMap(result.first);
  }

  static Future<void> deleteProgression(int id) async {
    await _db.transaction((txn) async {
      // Delete in order: ayahs → days → progression
      await txn.delete(
        'progression_ayahs',
        where: 'progression_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'progression_days',
        where: 'progression_id = ?',
        whereArgs: [id],
      );
      await txn.delete('progressions', where: 'id = ?', whereArgs: [id]);
    });
  }

  static Future<void> updateProgression(ProgressionModel progression) async {
    await _db.update(
      'progressions',
      progression.toMap(),
      where: 'id = ?',
      whereArgs: [progression.id],
    );
  }

  // ── Days CRUD ──────────────────────────────────────────────────────────

  static Future<int> insertDay(
    ProgressionDayModel day, {
    DatabaseExecutor? txn,
  }) async {
    return await (txn ?? _db).insert('progression_days', day.toMap());
  }

  static Future<List<ProgressionDayModel>> getDaysForProgression(
    int progressionId,
  ) async {
    final result = await _db.query(
      'progression_days',
      where: 'progression_id = ?',
      whereArgs: [progressionId],
      orderBy: 'day_number ASC',
    );
    return result.map((m) => ProgressionDayModel.fromMap(m)).toList();
  }

  static Future<void> updateDayStatus(
    int dayId,
    String status, {
    DatabaseExecutor? txn,
  }) async {
    await (txn ?? _db).update(
      'progression_days',
      {'status': status},
      where: 'id = ?',
      whereArgs: [dayId],
    );
  }

  // ── Ayahs CRUD ─────────────────────────────────────────────────────────

  static Future<void> insertAyahs(
    List<ProgressionAyahModel> ayahs, {
    DatabaseExecutor? txn,
  }) async {
    final executor = txn ?? _db;
    final batch = executor.batch();
    for (final ayah in ayahs) {
      batch.insert('progression_ayahs', ayah.toMap());
    }
    await batch.commit(noResult: true);
  }

  static Future<List<ProgressionAyahModel>> getAyahsForDay(int dayId) async {
    final result = await _db.query(
      'progression_ayahs',
      where: 'day_id = ?',
      whereArgs: [dayId],
      orderBy: 'ayah_number ASC',
    );
    return result.map((m) => ProgressionAyahModel.fromMap(m)).toList();
  }

  static Future<List<ProgressionAyahModel>> getAyahsForProgression(
    int progressionId,
  ) async {
    final result = await _db.query(
      'progression_ayahs',
      where: 'progression_id = ?',
      whereArgs: [progressionId],
      orderBy: 'ayah_number ASC',
    );
    return result.map((m) => ProgressionAyahModel.fromMap(m)).toList();
  }

  static Future<void> updateAyahStatus(
    int ayahId,
    String status, {
    DatabaseExecutor? txn,
  }) async {
    await (txn ?? _db).update(
      'progression_ayahs',
      {'status': status},
      where: 'id = ?',
      whereArgs: [ayahId],
    );
  }

  // ── Progress calculation ───────────────────────────────────────────────

  static Future<int> getCompletedAyahCount(int progressionId) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM progression_ayahs WHERE progression_id = ? AND status = ?',
      [progressionId, 'completed'],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  static Future<int> getCompletedDayCount(int progressionId) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM progression_days WHERE progression_id = ? AND status = ?',
      [progressionId, 'completed'],
    );
    return (result.first['count'] as int?) ?? 0;
  }
}
