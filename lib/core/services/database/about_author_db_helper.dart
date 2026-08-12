import 'package:the_message_of_the_quran/core/models/about_author_model.dart';
import 'package:the_message_of_the_quran/core/services/api/moq_api_client.dart';

class AboutAuthorDbHelper {
  static Future<List<AboutAuthorModel>> getAboutAuthor() async {
    final rows = await MoqApiClient.instance.getList('/about-author');
    return rows.map(AboutAuthorModel.fromJson).toList();
  }
}
