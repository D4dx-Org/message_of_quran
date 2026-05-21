import 'package:flutter/foundation.dart';
import 'package:the_message_of_the_quran/core/constants/db_constants.dart';
import 'package:the_message_of_the_quran/core/models/translator_note_model.dart';
import 'package:the_message_of_the_quran/core/services/database/database_helper.dart';

class TranslatorNoteDbHelper {
  static Future<List<TranslatorNoteModel>> getTranslatorNotes() async {
    final db = DatabaseHelper.quranAsadMalayalamDb;
    if (db == null) {
      debugPrint(
          'TranslatorNoteDbHelper: quranAsadMalayalamDb not initialized');
      return [];
    }

    try {
      final rows = await db.query(DbConstants.mlTranslatorNoteTable);
      return rows.map(TranslatorNoteModel.fromJson).toList();
    } catch (e) {
      debugPrint('TranslatorNoteDbHelper: Error fetching translator notes — $e');
      return [];
    }
  }
}
