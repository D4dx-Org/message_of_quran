import 'package:the_message_of_the_quran/core/models/authors_model.dart';
import 'package:the_message_of_the_quran/core/services/api/moq_api_client.dart';

class AuthorDbHelper {
  static Future<List<AuthorsModel>> getAuthors({bool malayalam = false}) async {
    final rows = await MoqApiClient.instance.getList(
      '/authors',
      query: {'malayalam': malayalam},
    );
    return rows.map(AuthorsModel.fromJson).toList();
  }
}
