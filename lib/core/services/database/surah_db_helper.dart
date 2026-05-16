import 'package:flutter/foundation.dart';
import 'package:the_message_of_the_quran/core/constants/db_constants.dart';
import 'package:the_message_of_the_quran/core/models/surah_model.dart';
import 'package:the_message_of_the_quran/core/services/database/database_helper.dart';

class SurahDbHelper {
  static Future<List<SurahModel>> getAllSuras({bool malayalam = false}) async {
    if (malayalam) {
      return _getAllSurasMalayalam();
    }
    return _getAllSurasAsad();
  }

  static Future<SurahModel?> getSurahByNumber(int surahNumber) async {
    final db = DatabaseHelper.quranAsadDb;
    if (db == null) {
      debugPrint('SurahDbHelper: quranAsadDb not initialized');
      return null;
    }

    try {
      final rows = await db.query(
        DbConstants.asadSurahsTable,
        where: '${DbConstants.asadSurahNumber} = ?',
        whereArgs: [surahNumber],
        limit: 1,
      );
      if (rows.isEmpty) return null;

      final row = rows.first;
      return SurahModel.fromAsadJson(
        row,
        arabicName: (row['arabic_name'] ?? '').toString(),
        malayalamName: (row['malayalam_name'] ?? '').toString(),
        ayathCount: (row['ayath_count'] as int?) ?? 0,
      );
    } catch (e) {
      debugPrint('SurahDbHelper: Error fetching surah $surahNumber — $e');
      return null;
    }
  }

  static Future<List<SurahModel>> _getAllSurasAsad() async {
    final db = DatabaseHelper.quranAsadDb;
    if (db == null) {
      debugPrint('SurahDbHelper: quranAsadDb not initialized');
      return [];
    }

    try {
      final rows = await db.query(
        DbConstants.asadSurahsTable,
        orderBy: '${DbConstants.asadSurahNumber} ASC',
      );

      return rows.map((row) {
        return SurahModel.fromAsadJson(
          row,
          arabicName: (row['arabic_name'] ?? '').toString(),
          malayalamName: (row['malayalam_name'] ?? '').toString(),
          ayathCount: (row['ayath_count'] as int?) ?? 0,
        );
      }).toList();
    } catch (e) {
      debugPrint('SurahDbHelper: Error fetching surahs — $e');
      return [];
    }
  }

  static Future<List<SurahModel>> _getAllSurasMalayalam() async {
    return _getAllSurasAsad();
  }
}
