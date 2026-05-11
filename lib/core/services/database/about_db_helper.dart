import 'package:the_message_of_the_quran/core/models/about_model.dart';

class AboutDbHelper {
  static Future<List<AboutModel>> getAboutInfo({bool malayalam = false}) async {
    // About data is not available in the current databases.
    return [];
  }
}