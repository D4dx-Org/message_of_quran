import 'package:the_message_of_the_quran/core/models/authors_model.dart';

class AuthorDbHelper {
  static Future<List<AuthorsModel>> getAuthors({bool malayalam = false}) async {
    // Author data is not available in the current databases.
    return [];
  }
}