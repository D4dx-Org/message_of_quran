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
    final mlDb = DatabaseHelper.quranAsadMalayalamDb;
    if (mlDb == null) {
      debugPrint('SurahDbHelper: quranAsadMalayalamDb not initialized');
      return [];
    }

    try {
      // Fetch ayah counts from the Asad DB since the Malayalam DB lacks them.
      final ayahCountMap = <int, int>{};
      final asadDb = DatabaseHelper.quranAsadDb;
      if (asadDb != null) {
        final asadRows = await asadDb.query(
          DbConstants.asadSurahsTable,
          columns: [DbConstants.asadSurahNumber, 'ayath_count'],
        );
        for (final r in asadRows) {
          final num = (r[DbConstants.asadSurahNumber] as int?) ?? 0;
          final count = (r['ayath_count'] as int?) ?? 0;
          ayahCountMap[num] = count;
        }
      }

      final rows = await mlDb.query(
        DbConstants.mlSurahsTable,
        orderBy: '${DbConstants.mlSurahChapterNumber} ASC',
      );

      return rows.map((row) {
        final chapterNumber =
            (row[DbConstants.mlSurahChapterNumber] as int?) ?? 0;
        return SurahModel(
          id: chapterNumber.toString(),
          surahNumber: chapterNumber,
          name: (row[DbConstants.mlSurahArabicName] ?? '').toString(),
          searchName: (row[DbConstants.mlSurahMalayalamName] ?? '')
              .toString()
              .trim()
              .toLowerCase(),
          arabicName: (row[DbConstants.mlSurahArabicName] ?? '').toString(),
          malayalamName:
              (row[DbConstants.mlSurahMalayalamName] ?? '').toString(),
          description:
              (row[DbConstants.mlSurahEnglishTranslation] ?? '').toString(),
          ayathCount: ayahCountMap[chapterNumber] ?? 0,
          place: (row[DbConstants.mlSurahRevelationPeriod] ?? '').toString(),
          introduction:
              (row[DbConstants.mlSurahIntroduction] ?? '').toString(),
          createdBy: '',
          createdByRole: '',
          isVerified: true,
        );
      }).toList();
    } catch (e) {
      debugPrint('SurahDbHelper: Error fetching Malayalam surahs — $e');
      return [];
    }
  }
}
