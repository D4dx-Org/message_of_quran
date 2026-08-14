import 'package:flutter/foundation.dart';
import 'package:the_message_of_the_quran/core/constants/db_constants.dart';
import 'package:the_message_of_the_quran/core/models/favorite_surah_model.dart';
import 'package:the_message_of_the_quran/core/services/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class FavoriteSurahDbHelper {
  static Future<List<FavoriteSurahModel>> getAll() async {
    final db = DatabaseHelper.userDatabase;
    if (db == null) return [];
    try {
      final result = await db.query(
        DbConstants.favoriteSurahsTableName,
        orderBy: '${DbConstants.favoriteCreatedAt} DESC',
      );
      return result.map((map) => FavoriteSurahModel.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> add(int surahNumber) async {
    final db = DatabaseHelper.userDatabase;
    if (db == null) return;
    try {
      await db.insert(
        DbConstants.favoriteSurahsTableName,
        FavoriteSurahModel(
          surahNumber: surahNumber,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('FavoriteSurahDbHelper: add failed — $e');
    }
  }

  static Future<void> remove(int surahNumber) async {
    final db = DatabaseHelper.userDatabase;
    if (db == null) return;
    try {
      await db.delete(
        DbConstants.favoriteSurahsTableName,
        where: '${DbConstants.favoriteSurahNumber} = ?',
        whereArgs: [surahNumber],
      );
    } catch (e) {
      debugPrint('FavoriteSurahDbHelper: remove failed — $e');
    }
  }
}
