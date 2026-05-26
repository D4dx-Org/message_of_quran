import 'package:flutter/foundation.dart';
import 'package:the_message_of_the_quran/core/constants/db_constants.dart';
import 'package:the_message_of_the_quran/core/models/about_model.dart';
import 'package:the_message_of_the_quran/core/services/database/database_helper.dart';

class AboutDbHelper {
  static Future<List<AboutModel>> getAboutInfo({bool malayalam = false}) async {
    if (malayalam) {
      return _getMalayalamAboutContent();
    } else {
      return _getEnglishAboutContent();
    }
  }

  static Future<List<AboutModel>> _getEnglishAboutContent() async {
    try {
      final db = DatabaseHelper.quranAsadDb;
      if (db == null) {
        debugPrint('AboutDbHelper: English database not initialized');
        return [];
      }
      final result = await db.query(DbConstants.enAboutUsTable);
      if (result.isEmpty) return [];
      return result.map((map) => AboutModel.fromEnglishJson(map)).toList();
    } catch (e) {
      debugPrint("Error fetching English about content: $e");
      return [];
    }
  }

  static Future<List<AboutModel>> _getMalayalamAboutContent() async {
    try {
      final db = DatabaseHelper.quranAsadMalayalamDb;
      if (db == null) {
        debugPrint('AboutDbHelper: Malayalam database not initialized');
        return [];
      }
      final result = await db.query(DbConstants.mlAboutUsTable);
      if (result.isEmpty) return [];
      return result.map((map) => AboutModel.fromJson(map)).toList();
    } catch (e) {
      debugPrint("Error fetching Malayalam about content: $e");
      return [];
    }
  }
}