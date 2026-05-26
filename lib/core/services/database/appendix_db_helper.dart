import 'package:flutter/foundation.dart';
import 'package:the_message_of_the_quran/core/constants/db_constants.dart';
import 'package:the_message_of_the_quran/core/models/appendix_model.dart';
import 'package:the_message_of_the_quran/core/services/database/database_helper.dart';

class AppendixDbHelper {
  static Future<List<AppendixModel>> getAppendices({
    bool malayalam = false,
  }) async {
    final db = malayalam
        ? DatabaseHelper.quranAsadMalayalamDb
        : DatabaseHelper.quranAsadDb;
    if (db == null) {
      debugPrint(
        'AppendixDbHelper: ${malayalam ? 'quranAsadMalayalamDb' : 'quranAsadDb'} not initialized',
      );
      return [];
    }

    try {
      final result = await db.query(
        DbConstants.appendicesTable,
        orderBy: '${DbConstants.appendixNumber} ASC',
      );
      return result.map((map) => AppendixModel.fromJson(map)).toList();
    } catch (e) {
      debugPrint('AppendixDbHelper: Error fetching appendices — $e');
      return [];
    }
  }

  static Future<AppendixModel?> getAppendixByNumber(
    int number, {
    bool malayalam = false,
  }) async {
    final db = malayalam
        ? DatabaseHelper.quranAsadMalayalamDb
        : DatabaseHelper.quranAsadDb;
    if (db == null) {
      debugPrint(
        'AppendixDbHelper: ${malayalam ? 'quranAsadMalayalamDb' : 'quranAsadDb'} not initialized',
      );
      return null;
    }

    try {
      final result = await db.query(
        DbConstants.appendicesTable,
        where: '${DbConstants.appendixNumber} = ?',
        whereArgs: [number],
      );
      if (result.isEmpty) return null;
      return AppendixModel.fromJson(result.first);
    } catch (e) {
      debugPrint(
        'AppendixDbHelper: Error fetching appendix $number — $e',
      );
      return null;
    }
  }
}
