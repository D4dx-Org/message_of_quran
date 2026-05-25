import 'package:flutter/foundation.dart';
import 'package:the_message_of_the_quran/core/constants/db_constants.dart';
import 'package:the_message_of_the_quran/core/models/english_translator_model.dart';
import 'package:the_message_of_the_quran/core/services/database/database_helper.dart';

class EnglishTranslatorDbHelper {
  static Future<List<EnglishTranslatorModel>> getTranslator() async {
    final db = DatabaseHelper.quranAsadDb;
    if (db == null) {
      debugPrint('EnglishTranslatorDbHelper: quranAsadDb not initialized');
      return [];
    }

    try {
      final rows = await db.query(DbConstants.asadTranslatorTable);
      return rows.map(EnglishTranslatorModel.fromJson).toList();
    } catch (e) {
      debugPrint('EnglishTranslatorDbHelper: Error fetching translator — $e');
      return [];
    }
  }
}
