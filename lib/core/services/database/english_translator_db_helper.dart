import 'package:the_message_of_the_quran/core/models/english_translator_model.dart';
import 'package:the_message_of_the_quran/core/services/api/moq_api_client.dart';

class EnglishTranslatorDbHelper {
  static Future<List<EnglishTranslatorModel>> getTranslator() async {
    final rows = await MoqApiClient.instance.getList('/translator');
    return rows.map(EnglishTranslatorModel.fromJson).toList();
  }
}
