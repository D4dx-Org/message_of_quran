import 'package:flutter/foundation.dart';
import 'package:the_message_of_the_quran/core/constants/db_constants.dart';
import 'package:the_message_of_the_quran/core/models/interpretation_model.dart';
import 'package:the_message_of_the_quran/core/services/database/database_helper.dart';

class InterpretationsDbHelper {
  static Future<List<InterpretationModel>> getinterpretations({
    required int surahNumber,
    required int interpretationNumber,
    bool malayalam = false,
  }) async {
    if (malayalam) {
      return _getInterpretationsThafeemMalayalam(
        surahNumber: surahNumber,
        ayahNumber: interpretationNumber,
      );
    }
    return _getInterpretationsAsad(
      surahNumber: surahNumber,
      interpretationNumber: interpretationNumber,
    );
  }

  static Future<List<InterpretationModel>> _getInterpretationsAsad({
    required int surahNumber,
    required int interpretationNumber,
  }) async {
    final db = DatabaseHelper.quranAsadDb;
    if (db == null) return [];
    try {
      final rows = await db.query(
        DbConstants.asadFootnotesTable,
        where: '${DbConstants.asadFootnoteSurahNumber} = ? AND ${DbConstants.asadFootnoteNumber} = ?',
        whereArgs: [surahNumber, interpretationNumber],
      );
      return rows.map((e) => InterpretationModel.fromAsadJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<InterpretationModel>> _getInterpretationsThafeemMalayalam({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final db = DatabaseHelper.quranAsadMalayalamDb;
    if (db == null) return [];
    try {
      final rows = await db.query(
        DbConstants.mlFootnotesTable,
        where: '${DbConstants.mlFootnoteNumber} = ?',
        whereArgs: [ayahNumber],
        orderBy: '${DbConstants.mlFootnoteId} ASC',
        limit: 1,
      );
      return rows.map((e) => InterpretationModel.fromMalayalamFootnoteJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, int>> getInterpretationRange({
    required int surahNumber,
    bool malayalam = false,
  }) async {
    if (malayalam) {
      return _getInterpretationRangeThafeemMalayalam(surahNumber: surahNumber);
    }
    return _getInterpretationRangeAsad(surahNumber: surahNumber);
  }

  static Future<Map<String, int>> _getInterpretationRangeAsad({
    required int surahNumber,
  }) async {
    final db = DatabaseHelper.quranAsadDb;
    if (db == null) return {'min': -1, 'max': -1};
    try {
      final result = await db.rawQuery(
        'SELECT MIN(${DbConstants.asadFootnoteNumber}) as min_num,'
        ' MAX(${DbConstants.asadFootnoteNumber}) as max_num'
        ' FROM ${DbConstants.asadFootnotesTable}'
        ' WHERE ${DbConstants.asadFootnoteSurahNumber} = ?',
        [surahNumber],
      );
      if (result.isEmpty) return {'min': -1, 'max': -1};
      return {
        'min': (result.first['min_num'] as int?) ?? -1,
        'max': (result.first['max_num'] as int?) ?? -1,
      };
    } catch (e) {
      debugPrint('InterpretationsDB: bounds query failed — $e');
      return {'min': -1, 'max': -1};
    }
  }

  static Future<Map<String, int>> _getInterpretationRangeThafeemMalayalam({
    required int surahNumber,
  }) async {
    final db = DatabaseHelper.quranAsadMalayalamDb;
    if (db == null) return {'min': -1, 'max': -1};
    try {
      // Extract footnote numbers from verse text [^N] markers for this surah
      final rows = await db.query(
        DbConstants.mlVersesTable,
        columns: [DbConstants.mlVersesMalayalamTranslation],
        where: '${DbConstants.mlVersesSurahId} = ?',
        whereArgs: [surahNumber],
      );
      final pattern = RegExp(r'\[\^?(\d+)\]');
      int minNum = -1;
      int maxNum = -1;
      for (final row in rows) {
        final text = (row[DbConstants.mlVersesMalayalamTranslation] as String?) ?? '';
        for (final match in pattern.allMatches(text)) {
          final num = int.tryParse(match.group(1)!);
          if (num != null) {
            if (minNum == -1 || num < minNum) minNum = num;
            if (maxNum == -1 || num > maxNum) maxNum = num;
          }
        }
      }
      return {'min': minNum, 'max': maxNum};
    } catch (e) {
      debugPrint('InterpretationsDB: Malayalam bounds query failed — $e');
      return {'min': -1, 'max': -1};
    }
  }

  /// Returns the first footnote/ayah number for the given surah as the default
  /// starting page when opening from an ayah tap.
  static Future<int> getInterpretationNumberForAyah({
    required int surahNumber,
    required int ayahNumber,
    bool malayalam = false,
  }) async {
    if (malayalam) {
      // In Malayalam mode, interpretation is per-ayah, so return the ayah number directly.
      return ayahNumber;
    }
    final range = await getInterpretationRange(
      surahNumber: surahNumber,
      malayalam: malayalam,
    );
    final min = range['min'] ?? -1;
    return min != -1 ? min : 1;
  }
}
