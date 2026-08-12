import 'package:the_message_of_the_quran/core/models/help_model.dart';

class HelpDbHelper {
  /// The source table is absent from the shipped db; backend returns an empty list.
  static Future<List<HelpModel>> getHelpInfo() async {
    return [];
  }
}
