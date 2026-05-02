import 'package:flutter/foundation.dart';
import 'package:the_message_of_the_quran/core/constants/db_constants.dart';
import 'package:the_message_of_the_quran/core/models/about_model.dart';
import 'package:the_message_of_the_quran/core/services/database/database_helper.dart';

class AboutDbHelper {
  static Future<List<AboutModel>>getAboutInfo()async{
    
    try {
    final aboutInfo = DatabaseHelper.quranAsadDb;
      if (aboutInfo == null) {
        debugPrint('AboutDbHelper: database not initialized');
        return [];
      }
      final result = await aboutInfo.query(
        DbConstants.aboutUsTableName,
      );
      // log(result.toString());
      return result.map((map) => AboutModel.fromJson(map)).toList();
      
    } catch (e) {
      debugPrint("Error fetching about info: $e");
      return [];
      
    }
   

  }
}