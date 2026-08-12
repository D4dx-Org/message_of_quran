import 'package:the_message_of_the_quran/core/models/authors_model.dart';
import 'package:the_message_of_the_quran/core/services/api/moq_api_client.dart';

class WorksOfReferenceDbHelper {
  static Future<List<AuthorsModel>> getWorksOfReference() async {
    final rows = await MoqApiClient.instance.getList('/works-of-reference');
    return rows.map(AuthorsModel.fromJson).toList();
  }
}
