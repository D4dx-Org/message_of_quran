import 'package:flutter/foundation.dart';
import 'package:the_message_of_the_quran/core/constants/db_constants.dart';
import 'package:the_message_of_the_quran/core/models/contact_content_model.dart';
import 'package:the_message_of_the_quran/core/models/contact_model.dart';
import 'package:the_message_of_the_quran/core/services/database/database_helper.dart';

class ContactDbHelper {
  static Future<List<ContactModel>> getContactInfo() async {
    try {
      final contactInfo = DatabaseHelper.quranAsadDb;
      if (contactInfo == null) {
        debugPrint('ContactDbHelper: database not initialized');
        return [];
      }
      final result = await contactInfo.query(
        DbConstants.contactTableName,
      );
      return result.map((map) => ContactModel.fromJson(map)).toList();
    } catch (e) {
      debugPrint("Error fetching contact info: $e");
      return [];
    }
  }

  static Future<ContactContentModel?> getContactContent() async {
    try {
      final db = DatabaseHelper.quranAsadMalayalamDb;
      if (db == null) {
        debugPrint('ContactDbHelper: Malayalam database not initialized');
        return null;
      }
      final result = await db.query(DbConstants.mlContactUsTable);
      if (result.isEmpty) return null;
      return ContactContentModel.fromJson(result.first);
    } catch (e) {
      debugPrint("Error fetching contact content: $e");
      return null;
    }
  }

  static Future<ContactContentModel?> getEnglishContactContent() async {
    try {
      final db = DatabaseHelper.quranAsadDb;
      if (db == null) {
        debugPrint('ContactDbHelper: English database not initialized');
        return null;
      }
      final result = await db.query(DbConstants.enContactUsTable);
      if (result.isEmpty) return null;
      return ContactContentModel.fromEnglishJson(result.first);
    } catch (e) {
      debugPrint("Error fetching English contact content: $e");
      return null;
    }
  }
}