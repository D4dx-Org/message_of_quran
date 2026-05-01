import 'package:flutter/foundation.dart';
import 'package:the_message_of_the_quran/core/constants/db_constants.dart';
import 'package:the_message_of_the_quran/core/models/contact_model.dart';
import 'package:the_message_of_the_quran/core/services/database/database_helper.dart';

class ContactDbHelper {
  static Future<List<ContactModel>>getContactInfo()async{
    try {

      final contactInfo = DatabaseHelper.quranMalayalamDb;
      if (contactInfo == null) {
        debugPrint('ContactDbHelper: database not initialized');
        return [];
      }
      final result=await contactInfo.query(
        DbConstants.contactTableName,
      );
      return result.map((map) => ContactModel.fromJson(map)).toList();
    } catch (e) {
      debugPrint("Error fetching contact info: $e");
      return [];
      
    }

  }

}